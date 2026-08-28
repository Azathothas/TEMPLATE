# scripts

The probe, the checks, and the helpers a project inherits.

⭐ **One command runs all of it**, and it is the one to reach for rather than
typing a list from memory:

```bash
sh scripts/common/check-gate.sh
```

```bash
pwsh -NoProfile -File scripts/common/check-gate.ps1 -Fast
```

| directory | what is in it |
| --- | --- |
| [`doctor/`](doctor/) | ⭐ the environment probe. Two implementations, one schema. Every project keeps this. |
| [`common/`](common/) | the checks and the helpers. ⛔ Every CHECK has a POSIX sh implementation AND a PowerShell twin. |
| [`powershell-windows/`](powershell-windows/) | tools for a job that only exists on Windows. ⛔ Not a twin of anything. |

⚠ **`powershell-windows/` exists because a job in it has no POSIX form, not
because a script was easier to write in PowerShell.** The distinction is the
whole point of the directory. `bash-posix/` does not exist and shipping it
empty would be shipping a phantom: git does not track an empty directory, so a
fresh clone would not have what this table described.

---

## ⭐ Everything in `common/` has two implementations, and here is what that cost

⛔ **A POSIX sh check cannot be assumed to run on Windows.** This was the
template's original position and it was wrong. The reasoning was that `sh`
would be present because Git Bash ships with git, so one implementation was
enough. Measured on one Windows 11 machine, 2026-08-25, from a native
PowerShell session with Git Bash NOT on `PATH`:

| tool the checks need | native PowerShell resolves it to |
| --- | --- |
| `sed` | ⛔ nothing. Not installed. |
| `sort` | ⚠ PowerShell's own `Sort-Object` alias, not the coreutils binary |
| `awk`, `grep`, `tr`, `comm`, `xargs` | present here only because scoop and a coreutils package happen to be installed |

⚠ **The second row is the dangerous one.** A missing tool fails loudly and
somebody fixes it. An ALIASED one succeeds and returns a DIFFERENT ANSWER.
`Sort-Object` even accepts `-u`, which is what makes it convincing. Measured on
the same machine, same day, over the five values `b A a B a`:

| | result |
| --- | --- |
| `LC_ALL=C sort -u` | `A B a b` |
| `Sort-Object -u` | ⛔ `A b` |

⛔ **It dropped two of the four distinct values**, because it compares
case-insensitively and keeps whichever it saw first. A check that deduplicates
a file list that way does not crash and does not warn. It reports on a smaller
set than it was asked about, and reports success.

⭐ **What did NOT reproduce, and is worth writing down so nobody re-derives
it:** git and `gh` behaved identically from both shells on this machine. Same
`git.exe` 2.55.0.windows.3, same `credential.helper manager` from the same
system config, same authenticated `gh`. So the argument for twins here is the
TOOLCHAIN, not credential scoping. A machine that installs git differently per
shell would add a second reason; this one did not have it.

### ⛔ Wherever a twin exists, `check-twins.sh` covers it

That is not advice, it is the rule that keeps two implementations from becoming
two behaviours. [`common/check-twins.sh`](common/) runs BOTH halves of every
pair on one tree and compares the `--json` answer and the exit code, then
compares `fill-license` on its OUTPUT because a corrupted licence exits 0.

⚠ **It compares ANSWERS on the tree it is run against, not the rules.** A scope
difference with nothing in the tree to exercise it is invisible: dropping `.py`
from one twin's extension list changed no number here, because this repository
has no `.py` file. Dropping `.md` was caught instantly. ⭐ Prove a scope rule
with a fixture, not by trusting the comparison to notice.

### The things that do NOT have twins, or are not compared, and why

| | |
| --- | --- |
| [`common/write-file.mjs`](common/) | ⛔ **It does not need one.** It is node, and node is the same program on every host: no `sed`, no `sort`, no shell built-ins, no aliases. The reason the sh checks needed twins does not apply to it. ⚠ What it needs instead is node itself, which is the one dependency anything under `scripts/` has, and the reason a project may decline this helper rather than inherit it. |
| [`common/check-twins.sh`](common/) | ⛔ **It cannot have one.** It works by running both halves of every pair, so it needs a POSIX shell to run the sh half no matter what language it is written in. A PowerShell twin would still require `sh`, which is the exact dependency a twin exists to remove. It is a maintainer's tool and it runs where both implementations do: this machine, and the CI job that has `pwsh` on an Ubuntu runner. |
| [`powershell-windows/wsl-ephemeral.ps1`](powershell-windows/) | ⛔ **No twin, and it must not get one.** It drives `wsl.exe`, which is a Windows feature. The POSIX "equivalent" would be a container or `systemd-nspawn`: a different tool solving a different problem, sharing no interface and no output. Calling those two a twin would put `check-twins.sh` in the position of comparing two unrelated programs, and the only way to make that pass is to compare nothing. |
| [`common/check-gate`](common/) | ⭐ **Has both halves, and is deliberately NOT compared.** It invokes `check-twins`, so putting the pair in `check-twins`'s own list would recurse. ⚠ The two exclusions are a shared contract: dropping either reintroduces a hang that once left twenty stray shells open. |
| [`common/mine-repo`](common/) | ⭐ **Has both halves, and is deliberately NOT compared.** A comparison would fetch a live third-party repository twice per run, making a local check depend on somebody else's uptime, and it writes a directory rather than a verdict. Proved by running both halves against one target instead, which is stronger evidence and caught a real defect. |

⭐ **The question to ask is whether the JOB exists on the other platform, not
whether the language does.** `wsl-ephemeral` fails that test. Every check in
`common/` passes it, which is why every one of them has two halves.
## The check contract

⛔ **Every check in this repository, and every check a project inherits from it,
satisfies all five.** A script that does not is not a check; it is a script
somebody has to remember to interpret.

1. **A header comment saying what defect it exists to catch.** Not what it
   does: what goes wrong without it. ⭐ This is the field that decides whether a
   future session keeps it, deletes it, or writes a second one that overlaps.
2. **Exit 0 pass, 1 fail, 2 could not run.** ⚠ Those are three different facts.
   "The check failed" and "the check could not run" mean opposite things about
   whether you can ship, and a script that returns 1 for both hides the
   difference.
3. **A json switch**, so a gate runner can consume it.
4. **No dependence on the directory it is run from.** Resolve paths from the
   script's own location.
5. **Read only, unless a fix flag is passed.** A check that repairs things by
   default is a check nobody can use to find out whether something is wrong.

⚠ **A check that measures an open defect must not fail the build for that
defect alone.** Record the count and judge it only past a stated ceiling.
⭐ The other half of that rule is that the exemption comes off when the item
closes. An exemption nobody removes is a check that stopped checking.

---

## ⛔ An exit code is read from the process that produced it, unpiped

```bash
sh scripts/common/check-no-secrets.sh
```

Not `check | grep`, not `check | Select-String`, not `check | tee`. A pipeline
reports the **last** command's status, so a check that failed reads as green.

⚠ This has caught the author of this sentence, in the session that wrote it.

---

## What is here

### `doctor/`

The environment probe. Read
[`doctor/README.md`](doctor/README.md) for the schema and the measured
runtimes.

⭐ It is a **probe, not a gate**: a missing tool is data, so it exits 0 whether
or not anything is missing. Nothing here belongs in a gate chain.

### `common/check-no-secrets.sh`

Does any file in this tree carry something that must not be published.

⚠ **Tracked plus untracked-but-not-ignored, not tracked alone.** A file that
has never been staged is exactly when a new file is likeliest to carry a
credential, and exactly what the next `git add -A` would take.

⛔ **It finds the shapes it knows, and a green run is not a clearance.** It
cannot find a password that looks like a word or a page of correct-looking
examples that happens to describe a real system.

`--public` adds the rules that only matter for a repository that will be
public: emails, absolute home paths, long hex identifiers. In a private project
those are legitimate content, which is why they are not the default.

### `common/check-one-home.sh`

Does any sentence of 12 words or more appear in two documents.

⛔ **The rule was in `prose.md` from the start and nothing checked it**, so it
drifted the way an unchecked rule always drifts. Its first run over this tree
found **42** duplicated sentences of 8 words or more, ⭐ five of them in
`docs/templates/RULES.md`, which is the skeleton this repository ships for
recording a project's rules and which opened by saying it restated nothing.
That file went from 198 lines to 134 and now links what it used to copy.

⚠ **THE FIRST VERSION OF THE INSTRUMENT REPORTED ZERO AND WAS WRONG.** Its file
collector handed git a quoted pathspec through a shell that treats a quote as
an ordinary character, so it matched nothing and reported a clean tree it had
never opened. ⭐ Both halves now refuse to report success over an empty scope,
and that is the only reason the number above exists.

⛔ **The three entry-point routers are exempt from each other and from nothing
else.** `AGENTS.md`, `ROUTE.md` and `docs/templates/AGENTS.md` state the
absolutes in full on purpose, because a session may be handed exactly one of
them. ⚠ A sentence shared between a router and any other file is still refused,
which was verified by planting one.

⚠ It compares SENTENCES, so a fact restated in different words passes here and
fails a review. That is the same split every prose rule has.

### `common/check-placeholders.sh`

Did a template placeholder survive into a real file. Run at the end of a
bootstrap, and as a gate afterwards.

### `common/check-gate.sh`

⭐ **Run the whole local gate with one command.** Part (a) of
[`../docs/methodology/gate.md`](../docs/methodology/gate.md) is a list, and a
list run by hand is run in the order somebody recalls it. The session that
wrote this ran its gate five times and typed a different subset each time.

It delegates and holds no rules of its own. ⛔ **A skipped check is reported as
a skip, never as a pass**, because a runner that dropped one quietly and
printed green would be the forbidden-patterns row about a step that exits 0
having done nothing. `--strict` makes a skip a failure, which is what CI should
pass; `--fast` drops `check-twins` and nothing else.

⛔ **Zero passes is red whatever the skips say.** It produced exactly the
opposite on its own first run: a broken presence test made every row report
"not present", and it printed a green verdict over nothing at all. That is the
defect its header describes, produced by the script itself, and it is the
argument for the rule.

⚠ **Neither half is in `check-twins.sh`'s pair list**, deliberately: this
runner invokes `check-twins`, so comparing the two runners from inside it would
recurse. An earlier version of this idea elsewhere did exactly that and left
twenty stray shells holding their own files open.

### `common/check-docs.sh`

Do the documents still resolve, and are they written the way this
repository writes documents. Relative links, fenced shell blocks that
parse, shell-unsafe placeholders, banned vocabulary, and orphan pages.

⚠ The template directories are exempt from the **link** check only: their
links are written relative to where the file will live in a project. The
prose rules still apply to them.

⛔ **The character rules are NOT here any more.** No em dash and no character
outside the five moved to `check-markers.sh`, which reads every tracked text
file rather than markdown alone. Two checks enforcing one rule is two places
for it to be wrong, which is the same move the control-byte rule already made
out of this file.

### `common/check-markers.sh`

Only the five defined characters, and not too many of them. Two rules, one
subject, one home.

⛔ **It reads every tracked text file.** The rule it inherited scanned markdown
alone, and on the day it was widened this repository's own scripts held **2290**
characters outside the five across 22 files. Every one was in a script, so the
markdown-only version had never seen any of them.

⭐ **The density ceiling is 30 markers per 100 non-blank lines, and the number
is measured rather than chosen.** Over three trees on 2026-08-28: the one that
reads worst 38.6 overall with a worst file of 53.3, this one 9.0 and 26.3, the
one that reads best 8.6 and 21.8. ⭐ The two ADOPTER trees had been ranked by
eye first and the ranking came out in that order. ⚠ This tree was not ranked
against them; its number simply falls between.

⚠ **Two exemptions, each load-bearing.** `LICENSES/*.txt` is canonical SPDX
text compared byte-for-byte elsewhere, so a check asking anybody to edit it
would be asking for a corruption. A **leading** byte-order mark is exempt
because every `.ps1` here needs one; a mark anywhere else is still reported.

⚠ **A specimen inside a code span is permitted**, because a page that bans a
character cannot otherwise show which one, and this file could not describe the
check without it.

### `common/check-twins.sh`

Do the two probe implementations still answer the same way. It runs both on
one machine and compares the schema, the section keys, and the host and repo
facts that describe that machine.

⚠ It compares the SHAPE and the FACTS, not the tool-by-tool verdicts. Each
twin reports what its own host can reach, and on a Windows machine with msys
installed `bash`, `tar` and `zsh` genuinely differ between them.

⭐ **It also compares the CLI surface, which the schema cannot show.** Every
comparison above reads what the probes OUTPUT; none of them reads what the
probes ACCEPT. `doctor.sh --text` exited 0 while `doctor.ps1 -Text` exited 1
with a parameter-binding error, and every other comparison in the file passed
the whole time that was true.

### `common/check-remote-items.sh`

What is open against the repository, and does it say anything that survives
being checked. For every pinned action a pull request proposes: the commit
exists in the repository the ref names, the tag comment resolves to that same
commit, and ⭐ the runtime it DECLARES is not one the platform has deprecated.

⛔ **It never merges, closes, comments or approves.** It reports, and deciding
is the operator's.

⚠ It cannot tell you whether a change is a good idea. It checks the facts an
item asserts about the world; whether you want the change is a reading.

⭐ It exists because this repository was pinned to an action targeting a Node
runtime GitHub had deprecated, and the warning sat in a log nobody read. A
dependency bot is right almost every time, and that is precisely what makes
the wrong one expensive.

### `common/check-control-bytes.sh`

Is there a literal control byte in any text file in the tree.

⭐ **It covers every text file, not only markdown.** The rule used to live in
`check-docs.sh` and scanned `.md` alone, which left every `.ts`, `.py`, `.rs`,
`.sh` and `.yml` unchecked for the one defect that makes a file invisible to
both review tools at once: `grep` calls it binary and skips it, and `git diff`
prints "Binary files differ" so a code review shows no diff at all.

⚠ The runtime value is identical either way, so only reviewability is ever at
stake. That is exactly why it survives unnoticed.

### `common/check-changelog.sh`

Does `CHANGELOG.md` still obey the four rules a machine can hold: newest first,
every heading dated, every entry naming its record, every entry saying whether
it deployed.

⭐ It exists because [`../docs/conventions/docs.md`](../docs/conventions/docs.md)
stated those four rules, said in as many words that each was mechanical enough
to check, and nothing checked them.

⚠ **No `CHANGELOG.md` is exit 2, not exit 0.** A project without one has
neither broken these rules nor satisfied them, and reporting green over an
absent file is how a check quietly stops applying.

### `common/fill-license.sh`

Write `LICENSE` from a canonical text with the holder filled in.

⛔ It **refuses** four of the twelve licences, on purpose. The GPL family's
copyright line belongs to the Free Software Foundation, and SPDX's ISC text
carries Internet Systems Consortium's own copyright.
[`../LICENSES/README.md`](../LICENSES/README.md) has the full reasoning.

---

## The helpers, which are not checks

⚠ **A helper writes; a check reports.** The five-point contract above is for
checks. These three are held to the header rule and the exit-code rule, and
deliberately not to "read only": writing is what they are for.

### `common/write-file.mjs`

Write, append to, or patch a file without the shell touching the payload.

⭐ **The payload channel is base64**, which is the one encoding no shell
interprets: not bash, not PowerShell, not `cmd`. A quote, a backtick, a dollar
sign, a percent and an emoji all survive it unchanged.

⛔ **A substitution whose match count differs from the number you declared is
REFUSED and the file is left untouched.** A silent no-op reporting success is
the failure this exists to remove. It fired twice while this template was
being maintained, once on a CRLF file whose LF search string matched nothing.

⚠ It needs `node`. That is the only thing under `scripts/` that does, and it
is the reason this is a helper a project may decline rather than a check every
project inherits. [`../docs/conventions/shell.md`](../docs/conventions/shell.md)
section 1 is the reasoning, measured.

### `common/mine-repo.sh`

Fetch everything a reference sweep needs, and ⭐ **keep it**.

⛔ **It exists because the evidence kept being thrown away.** One sweep kept its
conclusions and deleted eleven clones, so every citation became a claim nobody
could check. One session spent about fifteen minutes writing its own fetchers,
produced real data, and deleted the data and the fetchers on the way out
because both lived in session-local scratch. Same defect twice: the DERIVED
file treated as the product and the EVIDENCE as scratch.

It fetches metadata, issues and pull requests in both states, comments, review
comments, releases, tags, discussions where it can reach them, and the tree with
its commit captured **before** the strip. It writes a `PROVENANCE.md` naming the
commit, the route, and ⛔ what it could not get.

⚠ **It probes `gh` rather than assuming it**, because a token `command -v` says
is there has been dead on a live run, and falls back to a public proxy carrying
none of the caller's credentials. ⛔ Reads only, on both routes.

⚠ **Not in `check-twins.sh`.** Comparing two miners means fetching a live
third-party repository twice on every run, which would make a local check
depend on somebody else's uptime, and the output is a directory rather than a
verdict. ⭐ The pair was proved instead by running both halves and both routes
against one target: all four runs returned 26 issues, 13 comments, 0 review
comments, 1 release and 1 tag. That comparison is what caught the `ConvertTo-Json`
defect described in the `.ps1`, where a one-element array serialised as a bare
object and every count read as a field count.

### `common/deslop.sh`

Which files in this tree address a reader as an agent.

⭐ **An inventory, not a gate.** It exits 0 whether it finds forty or none,
exactly as the probe does, because in the repository that ships them their
presence is correct. Only `--apply` changes anything.

⛔ **`--apply` refuses on a dirty tree, deletes nothing outside the list it
printed, and never touches history.** Rewriting published history un-publishes
nothing, because every fork, mirror and archive keeps its copy, and it breaks
every clone and every open contribution.

⚠ **Whether a file addresses an agent is a reading**, so this matches names and
the default mode only prints. ⭐ It is anchored on the whole path for a reason:
an unanchored match on "agent" takes `src/agents/` in a project that builds one,
which is a deletion of somebody's source code. Both halves were run against
exactly that fixture, plus a lower-case `docs/agents.md` decoy, and neither
took either.

[`../docs/methodology/lean-adoption.md`](../docs/methodology/lean-adoption.md)
is the procedure, and ⭐ the cheaper path is never installing the files at all.

### `common/git-sync.sh`

Commit and push with the rules in
[`../docs/conventions/git.md`](../docs/conventions/git.md) enforced rather than
remembered.

⭐ **It arrived as a 674-line PowerShell script and now exists as both**: a
POSIX sh implementation so every Linux and macOS project can run it, and a
PowerShell twin because on Windows the sh one needs a POSIX layer that a native
session may not have. ⚠ On Windows prefer the `.ps1`: it drives the native
`git.exe` rather than one inside an msys layer.

⛔ **An AI-attribution line is refused, never stripped.** Rewriting somebody's
commit message is worse than declining it: the author never learns the rule.

⛔ **A CI-skip marker is refused unless the flag was passed.** A message that
merely mentions one skips CI, because the platform does not read the sentence
around it.

⚠ **It knows nothing about who you are.** Identity comes from the flags or from
git config, and if neither has one it refuses rather than guessing.

### `powershell-windows/wsl-ephemeral.ps1`

⭐ **A wrapper. The implementation lives in `Azathothas/ToolKit`** and this file
fetches it. Arguments pass through unchanged and the inner exit code is
propagated, so callers of the old path keep working.

**Why it moved.** A template that ships a working tool acquires that tool's
defects, its issues and its release cadence, and every project started from the
template inherits a snapshot nobody will ever update. One copy that can be
fixed once is the whole point. The template keeps the entry point; the tool
lives where it can have a backlog.

⛔ **It is pinned to a COMMIT and verified against a SHA-256 before anything
executes.** This wrapper downloads code and runs it, which is a supply chain,
and it gets the same discipline as a third-party action pin for the same
reason: a moving reference runs code nobody reviewed. A digest mismatch is a
hard stop, the cached copy is deleted, and no network with no verified cache is
an error rather than a silent skip. The `.NOTES` block in the file carries the
environment overrides and the two commands that refresh the pin.

⚠ **Bumping the pin is a deliberate act, so a fix upstream does not arrive on
its own.** That is the cost of pinning and it is the correct trade here: the
alternative is every project started from this template executing whatever
`main` says on the day it runs.

---

## Adding one

1. **Name the defect first.** If you cannot say what goes wrong without this
   script, it is not a check.
2. **Follow the contract**, all five points.
3. ⭐ **Mutation-prove it.** Plant the defect it exists to catch, run it, and
   read the exit code unpiped. **A guard that has never been seen to refuse is
   a guard nobody knows works.**

   This is not optional advice. While building this repository, a licence
   filler reported success over a licence whose warranty clause it had
   corrupted, because its check only ever asked whether a placeholder
   *survived*, never whether the substitution had reached too far. The mutation
   test is what found it.

4. **Wire it into the gate**, if it can fail.
5. **Document it**: here, and in the project's own tool table.

⚠ **A script that lives only in a transcript is re-derived every session.**
When a scratch helper does something a future session will also need, promote
it: write it into `scripts/` with the contract above, document it where agents
are told to look, and wire it into the gate if it is a check rather than a
one-off.
