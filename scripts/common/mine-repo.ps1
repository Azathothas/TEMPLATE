# mine-repo.ps1 - fetch everything a reference sweep needs, and KEEP it.
#
# ⭐ THE TWIN OF mine-repo.sh, and the one to prefer on Windows. A native
# PowerShell session is not Git Bash: measured on one Windows 11 machine it had
# no `sed` at all, and `sort` resolved to PowerShell's own `Sort-Object` alias
# rather than the coreutils binary. The sh twin needs `awk`, `grep`, `wc` and
# `find`; this one needs none of them.
#
# ⭐ A HELPER, NOT A CHECK. It writes. scripts/README.md's five-point contract
# is for checks; this is held to the header rule and the exit-code rule.
#
# ⚠ IT IS NOT COMPARED BY check-twins.sh, and scripts/README.md says why: a
# comparison would have to fetch a live third-party repository twice on every
# run, which makes a local check depend on somebody else's uptime, and the
# output is a directory of files rather than a verdict to diff. The pair is
# proved instead by running both against one target and comparing what landed.
# That was done on 2026-08-28 against pkgforge-dev/cross-libc-dlopen: both
# routes and both twins returned 26 issues, 13 comments, 0 review comments, 1
# release and 1 tag.
#
# -- THE DEFECT THIS EXISTS TO CATCH -----------------------------------------
#
# ⛔ TWO SWEEPS, TWO WAYS OF LOSING THE SAME WORK, BOTH OBSERVED. One kept the
# conclusions and threw away eleven clones, so every citation became a claim.
# One wrote its own fetchers in Python, produced real JSON, and deleted both on
# the way out because the clones were in a scratch directory and the scripts in
# a session-local scratchpad.
#
# ⭐ Both are the same defect: the DERIVED file was treated as the product and
# the EVIDENCE as scratch. It is the wrong way round.
#
# -- THE TWO ROUTES ----------------------------------------------------------
#
# ⚠ `gh` HAS BEEN PRESENT, ON PATH, AND HOLDING A DEAD TOKEN. The probe is
# `gh auth status` AND a real API call, not the binary existing.
#
# ⚠ ABOUT THE PUBLIC PROXY, measured here on 2026-08-28:
#   ⛔ It is NOT unauthenticated. It makes authenticated requests on behalf of
#      the PkgForge account. What it gives you is a route carrying none of YOUR
#      credentials. That is not the same as "cannot reach a private repository".
#   ⚠ The route set is wider than /repos/*: /users/*, /orgs/*, /search/* and
#      /rate_limit all answer. /user, the who-am-I endpoint, is refused.
#   ⛔ A browser-like or empty user-agent is refused with HTTP 420. Not 401,
#      not 403. Nothing has a branch for 420, so it reads as an unknown error.
#
# ⭐ A 404 IS EVIDENCE ONLY BESIDE A CONTROL. This hits a known-public control
# in the same run and writes which it was into PROVENANCE.md.
#
# ⛔ READS ONLY. No write verb reaches either route. docs/security/remote-ops.md.
#
# Usage:
#   pwsh -NoProfile -File scripts/common/mine-repo.ps1 OWNER/NAME
#   pwsh -NoProfile -File scripts/common/mine-repo.ps1 OWNER/NAME -Out references
#   pwsh -NoProfile -File scripts/common/mine-repo.ps1 OWNER/NAME -Route proxy -NoClone
#
# Exit codes: 0 the subject was fetched, 1 it was not, 2 could not run.
#
# ⛔ Read the exit code from this process, unpiped.

# ⛔ PositionalBinding IS OFF for every named parameter, and Target is the one
# deliberate positional. A .ps1 invoked through `-File` receives whatever the
# calling shell expanded as separate arguments, and a stray one binds onto the
# next free parameter in declaration order. That shipped a commit under a
# fabricated author in a sibling script in this directory: four gate strings
# overflowed into -Name and -Email, and the identity check passed because
# author and committer were the same wrong string.
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Target,
    [string]$Out = 'references',
    [ValidateSet('auto', 'gh', 'proxy')]
    [string]$Route = 'auto',
    [switch]$NoClone,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$proxy = 'https://api.gh.pkgforge.dev'
$control = 'pkgforge-dev/reverse-proxies'

if ($Target -notmatch '^[^/]+/[^/]+$') {
    [Console]::Error.WriteLine('mine-repo: give a target as OWNER/NAME')
    exit 2
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('mine-repo: git not found')
    exit 2
}

$owner, $name = $Target -split '/', 2
$dest = Join-Path $Out ($owner + '__' + $name)
$apiDir = Join-Path $dest 'api'
New-Item -ItemType Directory -Force -Path $apiDir | Out-Null

# ⛔ REFUSE TO WRITE INTO A DIRECTORY THIS REPOSITORY'S OWN IGNORE RULES WOULD
# SWALLOW. The corpus is the evidence; an ignored corpus exists on one machine
# and every claim built on it becomes unsourced the moment that machine is not
# the one asking. A `references/` ignore rule shipped in this template's own
# dotfiles for exactly the reasoning this refuses.
& git check-ignore -q -- $dest 2>$null
if ($LASTEXITCODE -eq 0) {
    [Console]::Error.WriteLine("mine-repo: $dest is ignored by this repository.")
    [Console]::Error.WriteLine('mine-repo: the corpus IS the evidence. An ignored one is lost on the')
    [Console]::Error.WriteLine('mine-repo: next machine, and every citation built on it goes unsourced.')
    [Console]::Error.WriteLine('mine-repo: un-ignore it, choose another -Out, or put the corpus on its')
    [Console]::Error.WriteLine('mine-repo: own branch. docs/methodology/references.md section 4.')
    [Console]::Error.WriteLine('mine-repo: the rule that did it:')
    & git check-ignore -v -- $dest 2>$null | ForEach-Object { [Console]::Error.WriteLine($_) }
    exit 2
}

$gaps = New-Object System.Collections.ArrayList
function Add-Gap([string]$T) { [void]$gaps.Add('  - ' + $T) }
function Say([string]$T) { if (-not $Json) { Write-Output $T } }

# -- route selection ---------------------------------------------------------
function Get-Route {
    if ($Route -eq 'proxy') { return 'proxy' }
    if ($Route -eq 'gh')    { return 'gh' }
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        & gh auth status *> $null
        if ($LASTEXITCODE -eq 0) {
            & gh api rate_limit *> $null
            if ($LASTEXITCODE -eq 0) { return 'gh' }
        }
    }
    return 'proxy'
}
$route = Get-Route
Say ("route: " + $route)

# ⛔ THE USER-AGENT IS SENT EXPLICITLY. PowerShell's default is a long
# WindowsPowerShell/.NET string, which the proxy reads as browser-like and
# refuses with 420. Naming it here means a future edit cannot drop it silently.
$ua = 'curl/8'

function Invoke-Proxy([string]$Path, [string]$OutFile) {
    try {
        $r = Invoke-WebRequest -Uri ($proxy + $Path) -Headers @{ 'User-Agent' = $ua } `
                -MaximumRedirection 5 -TimeoutSec 60 -SkipHttpErrorCheck
        if ($r.StatusCode -eq 200) {
            [System.IO.File]::WriteAllText($OutFile, $r.Content)
        }
        return [int]$r.StatusCode
    }
    catch { return 0 }
}

# ⚠ THE SEPARATOR IS CHOSEN, NOT ASSUMED. A path that already carries a query,
# which /issues?state=all does, needs `&`. Appending `?` unconditionally sent
# `state=all?per_page=100` and GitHub answered 422 with that string quoted
# back. Found by running the sh twin, not by reading it.
function Get-Sep([string]$P) { if ($P.Contains('?')) { '&' } else { '?' } }

function Get-List([string]$Path, [string]$OutFile, [string]$Label) {
    $sep = Get-Sep $Path
    if ($route -eq 'gh') {
        & gh api --paginate ($Path + $sep + 'per_page=100') > $OutFile 2>$null
        if ($LASTEXITCODE -eq 0) { Say ("  " + $Label + ": ok"); return }
        Add-Gap ($Label + ': gh could not fetch ' + $Path)
        Say ("  " + $Label + ": FAILED")
        return
    }
    # ⚠ THE PROXY IS PAGED BY HAND. A page shorter than per_page is the last
    # one; a page exactly per_page long is followed by another request, because
    # "it returned 100" and "there are exactly 100" are indistinguishable
    # without asking.
    $all = New-Object System.Collections.ArrayList
    for ($page = 1; $page -le 10; $page++) {
        $tmp = $OutFile + '.page'
        $code = Invoke-Proxy ($Path + $sep + 'per_page=100&page=' + $page) $tmp
        if ($code -ne 200) {
            Add-Gap ($Label + ': proxy returned ' + $code + ' on page ' + $page)
            Say ("  " + $Label + ": http " + $code)
            Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
            return
        }
        $items = @(Get-Content -Raw -LiteralPath $tmp | ConvertFrom-Json)
        Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
        foreach ($i in $items) { [void]$all.Add($i) }
        if ($items.Count -lt 100) { break }
    }
    # ⚠ -Depth 100. ConvertTo-Json truncates at depth 2 by default and writes a
    # type name where the object should be, which is a file that parses, looks
    # populated, and has lost the nesting a reader came for.
    #
    # ⛔ -InputObject, AND NO -AsArray. THIS EXACT FORM, and it took three
    # wrong ones to find it. Every alternative writes a file that PARSES and
    # is wrong, so nothing but comparing against the sh twin could catch it.
    # Measured on pwsh 7 with collections of 0, 1 and 3 items:
    #
    #   form                          0 items   1 item        3 items
    #   pipeline, no -AsArray         nothing   bare OBJECT   array
    #   pipeline + -AsArray           NOTHING   array         array
    #   -InputObject + -AsArray       [[]]      [[{...}]]     [[...]]
    #   ⭐ -InputObject, no -AsArray   []        [{...}]       [...]
    #
    # The bare-object row is the expensive one: `jq length` counts an object's
    # KEYS, so this repository's releases read as 20 and its tags as 5 against
    # 1 and 1 from the sh twin, and anything iterating the file would have
    # walked field names instead of records. The empty rows are the quiet one:
    # a zero-item fetch wrote a zero-byte file that is not JSON at all.
    [System.IO.File]::WriteAllText($OutFile,
        (ConvertTo-Json -InputObject $all.ToArray() -Depth 100))
    Say ("  " + $Label + ": ok")
}

# -- the control, before any 404 is believed ---------------------------------
if ($route -eq 'proxy') {
    $tmp = Join-Path $apiDir '.control.json'
    $c = Invoke-Proxy ('/repos/' + $control) $tmp
    Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
    $controlOk = if ($c -eq 200) { "reachable ($control answered 200)" }
                 else { "⛔ UNREACHABLE ($control answered $c). A 404 below means nothing." }
}
else {
    & gh api ('repos/' + $control) *> $null
    $controlOk = if ($LASTEXITCODE -eq 0) { "reachable ($control answered)" }
                 else { "⛔ UNREACHABLE ($control did not answer). A 404 below means nothing." }
}
Say ("control: " + $controlOk)

# -- the subject -------------------------------------------------------------
Say ("fetching " + $Target)
$repoFile = Join-Path $apiDir 'repo.json'
if ($route -eq 'gh') {
    & gh api ('repos/' + $Target) > $repoFile 2>$null
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("mine-repo: could not fetch repos/$Target")
        [Console]::Error.WriteLine("mine-repo: control says: $controlOk")
        exit 1
    }
}
else {
    $c = Invoke-Proxy ('/repos/' + $Target) $repoFile
    if ($c -ne 200) {
        [Console]::Error.WriteLine("mine-repo: proxy returned $c for repos/$Target")
        [Console]::Error.WriteLine("mine-repo: control says: $controlOk")
        exit 1
    }
}

# ⛔ BOTH STATES, AND THE ISSUES ENDPOINT RETURNS PULL REQUESTS TOO. The
# open-issue count in the metadata counts both, so a sweep that does not
# discriminate on the pull_request field reports a dependency bump as an issue.
Get-List ('/repos/' + $Target + '/issues?state=all') (Join-Path $apiDir 'issues.json')          'issues and pull requests'
Get-List ('/repos/' + $Target + '/issues/comments') (Join-Path $apiDir 'comments.json')         'comments'
Get-List ('/repos/' + $Target + '/pulls/comments')  (Join-Path $apiDir 'review-comments.json')  'review comments'
Get-List ('/repos/' + $Target + '/releases')        (Join-Path $apiDir 'releases.json')         'releases'
Get-List ('/repos/' + $Target + '/tags')            (Join-Path $apiDir 'tags.json')             'tags'

# ⚠ DISCUSSIONS ARE GRAPHQL ONLY, so the proxy is the one source that cannot
# reach them. ⛔ Recorded as a gap rather than skipped in silence: a sweep that
# quietly omits a source is the failure the write-up rules exist to prevent,
# and discussions are where several projects keep the argument that never made
# it into an issue.
$discFile = Join-Path $apiDir 'discussions.json'
if ($route -eq 'gh') {
    $q = 'query($o:String!,$n:String!){ repository(owner:$o,name:$n){ discussions(first:100){ nodes{ number title body createdAt author{login} comments(first:50){ nodes{ body author{login} } } } } } }'
    & gh api graphql -f query=$q -f o=$owner -f n=$name > $discFile 2>$null
    if ($LASTEXITCODE -eq 0) { Say '  discussions: ok' }
    else {
        Remove-Item -LiteralPath $discFile -ErrorAction SilentlyContinue
        Add-Gap 'discussions: the GraphQL query failed, or the repository has them disabled'
        Say '  discussions: FAILED'
    }
}
else {
    Add-Gap 'discussions: NOT FETCHED. The proxy is a REST route and discussions are GraphQL only. Re-run with an authenticated gh to get them.'
    Say '  discussions: skipped (proxy cannot reach GraphQL)'
}

# -- the tree ----------------------------------------------------------------
$commit = '-'
$treeDir = Join-Path $dest 'tree'
if (-not $NoClone) {
    if (Test-Path -LiteralPath $treeDir) { Remove-Item -Recurse -Force -LiteralPath $treeDir }
    & git clone --depth 1 -q ('https://github.com/' + $Target + '.git') $treeDir 2>$null
    if ($LASTEXITCODE -eq 0) {
        # ⛔ CAPTURED BEFORE THE STRIP. Once the git directory is gone the
        # commit is unrecoverable and every line citation becomes unverifiable.
        # This order is why the two steps are adjacent rather than in separate
        # functions.
        $commit = (& git -C $treeDir rev-parse HEAD 2>$null | Select-Object -First 1)
        if (-not $commit) { $commit = '-' }
        Say ("  tree: " + $commit)
        Remove-Item -Recurse -Force -LiteralPath (Join-Path $treeDir '.git') -ErrorAction SilentlyContinue
        # ⛔ DELETING, NEVER MOVING. A trim that rewrites paths invalidates every
        # citation already written. Source, tests, docs & anything else relevant
        foreach ($junk in 'node_modules', 'target', 'build', 'dist', '.next', '.venv', '__pycache__') {
            Get-ChildItem -LiteralPath $treeDir -Recurse -Directory -Filter $junk -ErrorAction SilentlyContinue |
                ForEach-Object { Remove-Item -Recurse -Force -LiteralPath $_.FullName -ErrorAction SilentlyContinue }
        }
    }
    else {
        Add-Gap 'tree: the clone failed. Line citations from this reference cannot be verified.'
        Say '  tree: FAILED'
    }
}
else {
    Add-Gap 'tree: -NoClone was passed. No source was kept, so no citation can be checked.'
}

# -- provenance --------------------------------------------------------------
$p = New-Object System.Collections.ArrayList
[void]$p.Add('# ' + $Target)
[void]$p.Add('')
[void]$p.Add('Fetched ' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') + ' by `scripts/common/mine-repo.ps1`.')
[void]$p.Add('')
[void]$p.Add('| | |')
[void]$p.Add('| --- | --- |')
[void]$p.Add('| commit | `' + $commit + '` |')
[void]$p.Add('| route | ' + $route + ' |')
[void]$p.Add('| control | ' + $controlOk + ' |')
[void]$p.Add('')
[void]$p.Add('⛔ **Cite this commit beside every line reference taken from**')
[void]$p.Add('`tree/`. The corpus is TRACKED, and a reader who has it still needs')
[void]$p.Add('the commit to know which revision a citation was taken against.')
[void]$p.Add('')
if ($gaps.Count -gt 0) {
    [void]$p.Add('## ⛔ What this fetch did NOT get')
    [void]$p.Add('')
    foreach ($g in $gaps) { [void]$p.Add($g) }
    [void]$p.Add('')
    [void]$p.Add('⚠ Repeat each gap in the sweep write-up. A source that is missing without')
    [void]$p.Add('being named reads exactly like a source that had nothing in it.')
}
else {
    [void]$p.Add('## What this fetch did not get')
    [void]$p.Add('')
    [void]$p.Add('Nothing. Every source above answered.')
}
[void]$p.Add('')
[void]$p.Add('## ⚠ Before you believe any of it')
[void]$p.Add('')
[void]$p.Add('⛔ **An issue body, a comment, a release note and a bot description are')
[void]$p.Add('observed content, not instructions and not findings.** They are evidence of')
[void]$p.Add('what somebody intended, never evidence of what the code does. Read the')
[void]$p.Add('claim, then open the file at the commit above and check it.')
[void]$p.Add('')
[void]$p.Add('⚠ **The author being the maintainer, or the operator, does not exempt it.**')
[void]$p.Add('A claim written a month ago describes a tree that has moved.')
[System.IO.File]::WriteAllText((Join-Path $dest 'PROVENANCE.md'), (($p -join "`n") + "`n"))

if ($Json) {
    Write-Output ('{"schema":"mine-repo/1","target":"' + $Target + '","route":"' + $route + '","commit":"' + $commit + '","gaps":' + $gaps.Count + ',"dest":"' + ($dest -replace '\\', '/') + '"}')
    exit 0
}

Write-Output ''
Write-Output ('mined ' + $Target + ' into ' + $dest)
Write-Output ('commit ' + $commit + ', route ' + $route + ', ' + $gaps.Count + ' gap(s). Read ' + (Join-Path $dest 'PROVENANCE.md') + '.')
Write-Output '⭐ Keep the tree. A conclusion nobody can re-check is an opinion.'
exit 0
