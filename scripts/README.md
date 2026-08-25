# scripts

The probe, the checks, and the helpers a project inherits.

| directory | what is in it |
| --- | --- |
| [`doctor/`](doctor/) | ⭐ the environment probe. Two implementations, one schema. Every project keeps this. |
| [`common/`](common/) | cross-platform helpers. Safe on any host, and they exit cleanly when something they need is absent. |
| `bash-posix/` | POSIX shell, for a POSIX host |
| `powershell-windows/` | PowerShell, for Windows |

⭐ **A helper goes in `common/` when it genuinely runs anywhere.** Not when it
might. A script that assumes GNU flags is not common, and finding that out on
somebody's Mac is worse than having two files.

---

## ⭐ When a script gets a twin, and when it must not

Two implementations of one job is two places for that job to be wrong, so a
twin has to earn itself. Exactly one thing here has:

| | |
| --- | --- |
| [`doctor/`](doctor/) | ⭐ **runs BEFORE you know what is installed.** That is its job, so it cannot require a POSIX layer: "is there a POSIX layer" is one of the questions it answers. It needs a native implementation per host family. |
| everything else | runs AFTER the probe has reported. By then `sh` is known present or known absent, and on Windows that means Git Bash, WSL or msys, all of which the probe names. A second implementation would add a drift surface and buy nothing. |

⛔ **A twin exists only where a single implementation cannot run, and wherever
one exists, [`common/check-twins.sh`](common/) covers it.** Adding a twin
without adding it there is how drift starts: one gets a fix, a field or a
flag, the other does not, and nobody notices because each works on its own
host.

---

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

What host is this, what is installed, and what is this repo. Read
[`doctor/README.md`](doctor/README.md) for the schema and the measured
runtimes.

⭐ It is a **probe, not a gate**: a missing tool is data, so it exits 0 whether
or not anything is missing. Nothing here belongs in a gate chain.

### `common/check-no-secrets.sh`

Does any tracked file carry something that must not be published.

⛔ **It finds the shapes it knows, and a green run is not a clearance.** It
cannot find a password that looks like a word or a page of correct-looking
examples that happens to describe a real system.

`--public` adds the rules that only matter for a repository that will be
public: emails, absolute home paths, long hex identifiers. In a private project
those are legitimate content, which is why they are not the default.

### `common/check-placeholders.sh`

Did a template placeholder survive into a real file. Run at the end of a
bootstrap, and as a gate afterwards.

### `common/check-docs.sh`

Do the documents still resolve, and are they written the way this
repository writes documents. Relative links, fenced shell blocks that
parse, shell-unsafe placeholders, control bytes, em dashes, and the three
defined markers.

⚠ The template directories are exempt from the **link** check only: their
links are written relative to where the file will live in a project. The
prose rules still apply to them.

### `common/check-twins.sh`

Do the two probe implementations still answer the same way. It runs both on
one machine and compares the schema, the section keys, and the host and repo
facts that describe that machine.

⚠ It compares the SHAPE and the FACTS, not the tool-by-tool verdicts. Each
twin reports what its own host can reach, and on a Windows machine with msys
installed `bash`, `tar` and `zsh` genuinely differ between them.

### `common/fill-license.sh`

Write `LICENSE` from a canonical text with the holder filled in.

⛔ It **refuses** four of the twelve licences, on purpose. The GPL family's
copyright line belongs to the Free Software Foundation, and SPDX's ISC text
carries Internet Systems Consortium's own copyright.
[`../LICENSES/README.md`](../LICENSES/README.md) has the full reasoning.

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
