#Requires -Version 5.1

<#
.SYNOPSIS
    Wrapper. Runs wsl-ephemeral.ps1 from Azathothas/ToolKit with the arguments
    given here.

.DESCRIPTION
    The implementation moved to https://github.com/Azathothas/ToolKit so that
    this template keeps only what every project needs. This file stays behind so
    existing callers keep working: every argument is passed through unchanged and
    the inner script's exit code is propagated.

    HOW IT FETCHES, AND WHY IT IS SHAPED THIS WAY

    This wrapper downloads code and then runs it. That is a supply chain, so it
    is pinned exactly the way this repository pins a third-party GitHub Action,
    and for the same reason: a moving reference runs code nobody reviewed.

      1. The URL names an immutable COMMIT, never a branch and never a tag.
         A branch moves. A tag can be pushed over.
      2. The downloaded bytes are checked against a pinned SHA-256 before
         anything executes. A digest mismatch is a hard stop, not a warning.
      3. The file is parsed as PowerShell before it is run, so a captive portal
         or a 404 page cannot reach the execution path even when verification
         was deliberately turned off.
      4. The cache key includes the ref, so changing the pin can never serve a
         stale copy of the old one.

    Nothing here weakens on failure. No network and no cache is an error with a
    message, never a silent skip.

.PARAMETER Arguments
    Not declared. Every argument is collected and forwarded verbatim, so this
    wrapper never has to restate the inner script's parameter list. Restating it
    is how a wrapper drifts from the thing it wraps.

.EXAMPLE
    .\wsl-ephemeral.ps1 -Action New -Image alpine:3.22

.EXAMPLE
    .\wsl-ephemeral.ps1 -Action New -Image debian:bullseye-slim -Command "ldd --version" -Ephemeral -Force

.EXAMPLE
    .\wsl-ephemeral.ps1 -Action Purge -Force

.NOTES
    Environment overrides, all optional:

      WSL_EPHEMERAL_LOCAL             run this local .ps1 instead. No network.
                                      The development and air-gapped path.
      WSL_EPHEMERAL_REF               fetch this git ref instead of the pin.
      WSL_EPHEMERAL_SHA256            expect this digest instead of the pin.
      WSL_EPHEMERAL_ALLOW_UNVERIFIED  set to 1 to run an overridden ref with no
                                      digest. Prints a warning every time.
      WSL_EPHEMERAL_CACHE             cache directory. Default is under
                                      %LOCALAPPDATA%\wsl-ephemeral\cache.

    To refresh the pin after the upstream script changes, read the two values
    from the API rather than typing them:

      gh api repos/Azathothas/ToolKit/commits/main --jq .sha
      gh api repos/Azathothas/ToolKit/contents/scripts/powershell-windows/wsl-ephemeral.ps1?ref=REF --jq .content | base64 -d | sha256sum

    Requires : Windows PowerShell 5.1 or PowerShell 7+.
    ASCII-ONLY ON PURPOSE. docs/conventions/shell.md section 8: a .ps1 holding
    any non-ASCII byte needs a UTF-8 BOM before 5.1 will decode it correctly.
    Staying ASCII removes the requirement rather than depending on it.
#>

# CI runs Invoke-ScriptAnalyzer over scripts/ at Error and Warning. Each
# suppression is scoped to one rule and carries its reason. Do not replace these
# with a settings file that switches a rule off for every script.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Progress and diagnostics for a human at a terminal, which is the documented case for Write-Host. Nothing here is a value another script consumes: the inner script''s exit code is propagated and callers read that.')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# The pin. Both values move together or not at all.
# ---------------------------------------------------------------------------
$UpstreamOwner = 'Azathothas'
$UpstreamRepo  = 'ToolKit'
$UpstreamPath  = 'scripts/powershell-windows/wsl-ephemeral.ps1'
$PinnedRef     = '77596be12a8cddb9b636ec70e9faaa21c80fb359'
$PinnedSha256  = '2a4f8fc453728302e338e7c499cd4f7da80d92be76c99744ae0c0c98f19e17c2'

function Write-Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "  ! $Message" -ForegroundColor Yellow }

function Get-EnvOrDefault {
    param([Parameter(Mandatory = $true)][string]$Name, [AllowEmptyString()][string]$Fallback = '')
    $v = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($v)) { return $Fallback }
    return $v.Trim()
}

function Assert-PowerShellSyntax {
    <#
      A downloaded file that is not PowerShell must never reach the execution
      path. The realistic case is not a hostile payload, it is a captive portal
      or a 404 body arriving with HTTP 200.
    #>
    param([Parameter(Mandatory = $true)][string]$LiteralFile)
    $errs = $null
    $tokens = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($LiteralFile, [ref]$tokens, [ref]$errs)
    if ($errs -and $errs.Count -gt 0) {
        throw ("Downloaded file is not valid PowerShell (first error: line " +
               $errs[0].Extent.StartLineNumber + ": " + $errs[0].Message + "). " +
               "This usually means a proxy or a captive portal answered instead of GitHub.")
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralFile)
    return (Get-FileHash -LiteralPath $LiteralFile -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Save-Upstream {
    <# Download to a temp file in the destination directory, then rename. #>
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination
    )
    $dir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $temp = Join-Path $dir ('.download.' + [Guid]::NewGuid().ToString('N') + '.tmp')

    # Windows PowerShell 5.1 negotiates TLS 1.0 on some machines and GitHub
    # refuses it, which surfaces as "The request was aborted: Could not create
    # SSL/TLS secure channel" and reads like an outage. PowerShell 7 already
    # defaults correctly; setting it is harmless there.
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch { $null = $_ }

    # The progress bar makes Invoke-WebRequest an order of magnitude slower on
    # 5.1 and writes nothing a caller needs.
    $prevProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $temp -UseBasicParsing -TimeoutSec 30
        if (-not (Test-Path -LiteralPath $temp)) { throw "download produced no file" }
        if ((Get-Item -LiteralPath $temp).Length -lt 1KB) {
            throw "downloaded file is implausibly small ($((Get-Item -LiteralPath $temp).Length) bytes)"
        }
        Move-Item -LiteralPath $temp -Destination $Destination -Force
    }
    finally {
        $ProgressPreference = $prevProgress
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
    }
}

try {
    # --- the local escape hatch, before any network is touched ---------------
    $local = Get-EnvOrDefault 'WSL_EPHEMERAL_LOCAL'
    if ($local) {
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) {
            throw "WSL_EPHEMERAL_LOCAL points at '$local', which is not a file."
        }
        $resolved = (Resolve-Path -LiteralPath $local).Path
        Write-Step "Using local script (WSL_EPHEMERAL_LOCAL): $resolved"
        & $resolved @args
        $inner = if (Test-Path variable:LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        exit ([int]$inner)
    }

    # --- resolve the pin and any override ------------------------------------
    $ref      = Get-EnvOrDefault 'WSL_EPHEMERAL_REF' $PinnedRef
    $expected = (Get-EnvOrDefault 'WSL_EPHEMERAL_SHA256' '').ToLowerInvariant()
    $refIsPinned = ($ref -eq $PinnedRef)

    if ($refIsPinned -and -not $expected) { $expected = $PinnedSha256.ToLowerInvariant() }

    # The pin must be a COMMIT. Tested by shape, not by comparing against a
    # magic placeholder string: a search-and-replace that fills the pin in also
    # rewrites the placeholder it is compared against, which inverts this guard
    # into throwing whenever the pin IS in use. That happened while this file
    # was being pinned. Testing the shape also catches the likelier mistake of
    # pinning to a branch, which is the thing the guard exists to prevent.
    if ($refIsPinned -and $ref -notmatch '^[0-9a-fA-F]{40}$') {
        throw ("This wrapper is not pinned to a commit (got '$ref'). A branch or a tag " +
               "moves, so it is refused. Set WSL_EPHEMERAL_LOCAL, or set WSL_EPHEMERAL_REF " +
               "with WSL_EPHEMERAL_SHA256, or write a 40-character commit SHA into this file.")
    }

    $verify = $true
    if (-not $expected) {
        # An overridden ref with no digest. Deliberate bypass only.
        if ((Get-EnvOrDefault 'WSL_EPHEMERAL_ALLOW_UNVERIFIED') -ne '1') {
            throw ("WSL_EPHEMERAL_REF is set to '$ref' but no WSL_EPHEMERAL_SHA256 was given. " +
                   "Supply the digest, or set WSL_EPHEMERAL_ALLOW_UNVERIFIED=1 to run it unverified.")
        }
        $verify = $false
        Write-Warn "running an UNVERIFIED ref '$ref': no digest was supplied."
    }

    # --- cache, keyed by ref so a pin change cannot serve the old copy -------
    $cacheDir = Get-EnvOrDefault 'WSL_EPHEMERAL_CACHE'
    if (-not $cacheDir) {
        if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
            throw "LOCALAPPDATA is not set and WSL_EPHEMERAL_CACHE was not given; nowhere to cache."
        }
        $cacheDir = Join-Path $env:LOCALAPPDATA 'wsl-ephemeral\cache'
    }
    $safeRef = ($ref -replace '[^A-Za-z0-9._-]', '-')
    $cached  = Join-Path $cacheDir ("wsl-ephemeral-$safeRef.ps1")

    $uri = "https://raw.githubusercontent.com/$UpstreamOwner/$UpstreamRepo/$ref/$UpstreamPath"

    # A cached copy is used only when it still matches the digest. An unverified
    # run cannot trust a cache either, so it always re-downloads.
    $useCache = $false
    if ($verify -and (Test-Path -LiteralPath $cached -PathType Leaf)) {
        if ((Get-Sha256 -LiteralFile $cached) -eq $expected) { $useCache = $true }
        else { Write-Warn "cached copy failed its digest check; re-downloading." }
    }

    if (-not $useCache) {
        Write-Step "Fetching $UpstreamOwner/$UpstreamRepo@$($ref.Substring(0, [Math]::Min(12, $ref.Length)))"
        try {
            Save-Upstream -Uri $uri -Destination $cached
        }
        catch {
            # No network. A verified cache is a correct answer; anything else is
            # an error, because guessing here means running the wrong code.
            if ($verify -and (Test-Path -LiteralPath $cached -PathType Leaf) -and
                (Get-Sha256 -LiteralFile $cached) -eq $expected) {
                Write-Warn "fetch failed ($($_.Exception.Message.Trim())); using the verified cached copy."
            }
            else {
                throw ("Could not fetch $uri and no verified cached copy exists.`n" +
                       "  Underlying error: $($_.Exception.Message.Trim())`n" +
                       "  Offline? Point WSL_EPHEMERAL_LOCAL at a local copy of the script.")
            }
        }
    }

    if ($verify) {
        $actual = Get-Sha256 -LiteralFile $cached
        if ($actual -ne $expected) {
            Remove-Item -LiteralPath $cached -Force -ErrorAction SilentlyContinue
            throw ("DIGEST MISMATCH for $uri`n" +
                   "  expected $expected`n" +
                   "  actual   $actual`n" +
                   "  Refusing to run it. The cached copy has been deleted.")
        }
    }

    Assert-PowerShellSyntax -LiteralFile $cached

    & $cached @args
    $innerCode = if (Test-Path variable:LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    exit ([int]$innerCode)
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
