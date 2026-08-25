# dotfiles

Ignore, attribute, editor and CI files, by ecosystem. The bootstrap selects
what applies and deletes the rest.

---

## ⛔ They ship without the leading dot, and that is deliberate

A file named `.gitignore` inside this repository would be a **real ignore file
for the directory it sits in**. `dotfiles/node/.gitignore` would silently apply
to `dotfiles/node/`, and `dotfiles/common/.gitattributes` would silently change
how git treats these very files.

So they are named `gitignore`, `gitattributes`, `editorconfig`, and the
bootstrap renames them on the way out.

⚠ **Check the result after renaming.** A dot-file that did not get its dot is
invisible in a plain listing and does nothing at all, which is a failure that
looks exactly like success:

```bash
ls -a
```

```bash
git check-ignore -v some/path/that/should/be/ignored
```

⭐ **`git check-ignore -v` names the file and line that matched.** It is the
only way to be sure a rule is doing what you think, and it takes one second.

---

## How they combine

An ignore file is **concatenated**, not chosen. A node project gets three:

```bash
cat dotfiles/common/gitignore dotfiles/os-editor/gitignore dotfiles/node/gitignore > .gitignore
```

| file | when |
| --- | --- |
| `common/gitignore` | always. Secrets, scratch, logs, local databases, agent files. |
| `os-editor/gitignore` | always. Operating system and editor noise. |
| `<ecosystem>/gitignore` | one per ecosystem the project actually uses |
| `common/gitattributes` | always. Line endings and binary declarations. |
| `common/editorconfig` | always. The working-tree half of gitattributes. |
| `github/` | when the remote is GitHub and CI was chosen |

⚠ A project can be several ecosystems at once. The probe reports what the tree
declares:

```bash
sh scripts/doctor/doctor.sh --json
```

Its `repo.ecosystems` field is read from manifest files that are actually
present, which is evidence rather than a guess from a directory name.

---

## The rules these encode

Each is written into the files themselves, and each has cost somebody a bad
afternoon.

- ⛔ **Secrets are listed before the files exist**, so one can never be staged
  by accident. A credential ignored after the fact was trackable in between.
- ⛔ **`.gitignore` only applies to files git is not already tracking.** Adding
  a line does not untrack what is already in.
- ⛔ **`nul` is a Windows reserved device name.** Redirecting to `/dev/null`
  under a shell that does not map it creates a real file called `nul`, which
  git tracks, which breaks `git stash` outright, and which cannot be deleted by
  `rm` or by Python.
- ⛔ **A lockfile is committed.** Every ecosystem file says so where it applies,
  as a comment rather than as a rule, because a project without one installs a
  different dependency tree every time.
- ⛔ **`.ps1` keeps CRLF.** Windows PowerShell 5.1 mis-parses a here-string
  whose terminator arrives with a bare LF. This is the one exception in
  `gitattributes` and it is not a preference.
- ⚠ **Runners are tracked; captures are not.** A benchmark script is source. Its
  output is a machine-and-day artefact. The one run that **is** the evidence for
  an item goes in on purpose:

```bash
git add -f bench/the-one-that-matters.json
```

- ⚠ **A cloned reference tree is not committed; the write-up is.** The trees are
  re-clonable from the URL the write-up records. A required-reading file that
  exists on one machine is one deletion away from leaving every claim built on
  it unsourced. See
  [`../docs/methodology/references.md`](../docs/methodology/references.md).

---

## Line endings, and the check that holds them

`gitattributes` normalises the **index** to LF. That is the half that decides
what a commit contains.

⚠ The working tree is a different matter, and drift there is invisible to git:
a carriage return in a file the attributes say is LF shows no diff at all,
because the index is normalised either way. It is very visible to any regex
that reads the working tree.

⚠ **The drift arrives from your own tooling**, not from an editor. Most
file-writing tools write CRLF on Windows by default.

```bash
git ls-files --eol
```

That prints, per tracked file, the index ending, the working-tree ending, and
the attributes git resolved. ⭐ **It is git's own answer, so a check built on it
cannot disagree with git**, which a second table of rules eventually would.

---

## Adding an ecosystem

1. Create `dotfiles/<name>/gitignore`.
2. ⛔ **Every entry earns its place.** An ignore rule for something this
   ecosystem does not produce is noise that a future reader has to evaluate.
3. **Say which artefacts are committed**, as comments. Lockfiles and build-tool
   wrappers are the two people get wrong.
4. Add the ecosystem's detection to the probe's manifest map, in **both** twins,
   so `repo.ecosystems` reports it.
5. Test it, rather than reasoning about it:

```bash
git check-ignore -v path/that/should/be/ignored
```
