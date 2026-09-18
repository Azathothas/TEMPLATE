# upstream-tool-shape.md

What this repository used to say about a tool it does not ship, and the two
ways that wording went wrong. Retired on 2026-09-18.

---

## ⭐ The shape of the defect, which is the part worth keeping

⛔ **A claim about somebody else's tree cannot be checked from this one.** Every
other stale sentence here is caught eventually, because the thing it describes
is in this repository and somebody opens it. A sentence about an upstream
product is different: it stays confidently wrong for as long as nobody happens
to read both trees on the same day.

⚠ **It was upstream that noticed, not this repository.** `Azathothas/ToolKit`
keeps a register of who depends on it, and on 2026-09-13 that register carried
a row naming this repository, the two files below, what they said, and the
remedy. Read on 2026-09-18, its remedy column read: rewrite its guide from the
latest manual.

⭐ **That is the argument for the rule that replaced this text.**
[`../containers.md`](../containers.md) now says what the procedure is and links
upstream's own skill for what the tool is, and
[`../agent-tooling.md`](../agent-tooling.md) carries a name, a link and one
line per row, with no product shape in it.

---

## 1. The retired wording, `docs/containers.md`

Kept verbatim. It was correct when it was written and it survived two later
maintenance passes over the same file.

> It is two products now, and a caller gets the compiled one by default.
> Upstream ships a PowerShell script and an executable that carries that same
> script inside itself and adds to it, and its launcher resolves the executable
> first. A page here that names its flags is a page that goes stale without
> anybody editing it, so this one does not: read the tool's own documentation
> at the link. What matters at this level is that the two exist, that a caller
> can ask for either, and that "the version I ran" is now a question with two
> answers.

⚠ **Read the middle sentence again.** The paragraph states the rule it is
breaking, in its own second sentence, and then breaks it in the first and the
third. It refuses to name a flag and then describes a launcher's resolution
order, which is behaviour, and a product count, which is a shape. ⭐ Declining
the obvious version of a rule is not the same as following it.

## 2. The retired wording, `docs/agent-tooling.md`

Two rows. The first carried a product shape in a file whose own header says it
carries names, links and one line each and nothing else. The second named a
tool upstream has replaced.

> `wsl-toolkit` [...] surveys the host, owns one WSL distro with a container
> engine in it, runs a command in a container or a set of them, and removes
> what it made. Two products, one of them compiled.

> `write-file` [...] writes or patches a file without the shell touching the
> payload.

⚠ **`write-file.mjs` still exists upstream**, so this row was not broken in the
way a dead link is broken. It named the tool that is no longer the answer, which
is the harder case: a session that followed it got a working tool and never
learned that a better one had shipped. `text-tool` replaced it, carries an
executable per host rather than a `node` dependency, refuses a substitution
whose match count was not stated, and has a skill of its own.

---

## What withdrew it

| claim | what withdrew it |
| --- | --- |
| the tool is two products, one a PowerShell script | upstream's `tools/windows/wsl-toolkit/README.md`, read 2026-09-18: the executable is the only product published from that repository, and the PowerShell product's only remaining trace is a recorded log used as test data. Its `docs/consumers.md` states the deletion outright. |
| `write-file` is the helper to reach for | upstream's `skills/text-tool/SKILL.md`, read 2026-09-18, and the release assets listed in its `docs/consumers.md` |
