# BOOTSTRAP.md

The procedure that turns this template into a project. Read it end to end
before running step 1. It happens once per project and it sets every rule that
follows, so partial reading here is a defect rather than a judgement call.

**The output of a bootstrap is a configured repository, a plan, and the first
unit of work, presented for approval.** It is not project code. Nothing is
implemented in a bootstrap session.

---

## Step 0. Detach the remote, before anything else

⛔ **This is first and it has no prerequisite.** A fresh clone has `origin`
pointing at the template. Every later step writes files, and a writing session
with the wrong remote configured is one `git push` away from putting one
project's history into every future project's starting point.

```bash
git remote -v
```

```bash
git remote remove origin
```

If the operator wants the template's history gone as well, and they almost
always do, the project starts from a clean history rather than from the
template's commits:

```bash
rm -rf .git && git init
```

⚠ Confirm which of those two the operator wants before running the second one.
Keeping the history means every project carries the template's commit log;
discarding it means the template's provenance is only in this file. Discarding
is the default and the operator has to say so only if they want otherwise.

Nothing else in this procedure runs until `git remote -v` prints nothing, or
prints a remote the operator named.

---

## Step 1. Measure the machine

```bash
sh scripts/doctor/doctor.sh
```

```bash
pwsh -NoProfile -File scripts/doctor/doctor.ps1
```

Read [`../scripts/doctor/README.md`](../scripts/doctor/README.md) first if you
have not. It is short and it says what each field means and what the probe
cannot answer.

What to take from the output:

| field | what it decides |
| --- | --- |
| `host.os`, `host.flavor`, `host.wsl` | which script dialect the project gets, which line endings, which path separators |
| `repo.ecosystems` | which `dotfiles/` subdirectory applies, when a tree already exists |
| `tools[]` | what the plan may rely on, and what has to be installed first |
| `notes[]` | a tool that is present but not working, which reads as available and is not |

⛔ **Run this even when the operator has stated the environment.** A stated
fact and a measured one that disagree is a finding. Report it rather than
quietly preferring one of them. The operator's claim about their own machine is
usually right and occasionally a year old.

---

## Step 2. Read the operator's answers

If the operator pasted [`ANSWERS.md`](ANSWERS.md), that is the input. If they
pasted a paragraph instead, treat it as the same thing with more blanks.

Three rules for handling it:

1. **A blank field is a default, not a question.** Take the default named in
   `ANSWERS.md`, and list what you defaulted when you report back. The operator
   objects to a list far more cheaply than they answer twenty questions.
2. **Ask only where the two readings produce different projects.** Group every
   such question into one exchange with a recommendation attached to each, so
   agreeing to all of it costs nothing. An interrogation is as much a failure
   as a silent wrong guess.
3. ⛔ **Never ask for the value of a secret.** The operator names what they
   hold; you say where it goes. Read
   [`../docs/security/secrets.md`](../docs/security/secrets.md) before writing
   any file that mentions one.

The forks that are usually genuine, and are worth asking about together:

- **Audience and scale**, if blank and the project could plausibly be either
  one person or a service. It decides more of the architecture than any other
  answer.
- **Visibility**, if blank and the project could plausibly be published. It
  changes what may enter the tree, the licence, and whether CI is free.
- **The work model**, if the shape genuinely sits between the two. See
  [`../docs/methodology/choosing-a-work-model.md`](../docs/methodology/choosing-a-work-model.md)
  and come with a recommendation rather than the question alone.
- **A stack choice that is load-bearing**, where you would recommend something
  other than what the operator named.

---

## Step 3. Decide what the project keeps

The template ships more than any one project needs. Everything not selected is
deleted, and deletion is part of the bootstrap rather than a later tidy. A file
nobody selected is a file a future session reads, believes, and follows into a
rule that was never meant to apply here.

| what | rule |
| --- | --- |
| `docs/methodology/gate.md`, `reviews.md`, `sessions.md`, `authoring.md` | always kept. Every project runs these. |
| `docs/methodology/initialize.md` | kept for a greenfield project, deleted for an adopt |
| `docs/methodology/ingest.md` | kept for an adopt, deleted for a greenfield project |
| `docs/methodology/work-stages.md` / `work-todo.md` | keep the one the model selects, delete the other, delete `choosing-a-work-model.md` once chosen |
| `docs/methodology/references.md` | kept when the project will study external code, which is most of them |
| `docs/conventions/*` | `prose.md`, `docs.md`, `git.md`, `code.md`, `forbidden-patterns.md` and `shell.md` are all kept |
| `docs/security/*` | both kept, always |
| `docs/public/` vs `docs/private/` | keep the one that matches visibility, delete the other |
| `dotfiles/common/` | always |
| `dotfiles/<ecosystem>/` | keep what the probe found or the operator named, delete the rest |
| `dotfiles/github/` | keep if the remote is GitHub and CI was chosen |
| `LICENSES/` | keep the chosen licence as the project's `LICENSE`, delete the directory |
| `scripts/doctor/` | always kept. Every later session runs it, and a resuming session on a different machine needs it most. |
| `scripts/<lang>-<host>/` | keep the dialect the host runs |
| `tools/` | deleted unless something in the plan genuinely needs a compiled helper |
| `bootstrap/` | ⛔ deleted, last, in step 7 |

⚠ **When unsure whether to keep a doc, keep it and say so in the report.** A
kept file the operator deletes costs one line. A deleted file whose rule the
project needed costs a defect nobody can trace.

---

## Step 4. Write the project's own AGENTS.md

Write it from [`../docs/templates/AGENTS.md`](../docs/templates/AGENTS.md).

⛔ **It replaces this repository's `AGENTS.md` entirely.** The template's router
is about bootstrapping and about maintaining the template, and neither applies
once a project exists. Leaving it in place points every future session at
instructions for a job that is finished.

The project's `AGENTS.md` is a router too, and it is held to the same rule:
it restates nothing and links everything. What it must carry, and nothing more:

- one paragraph on what the project is and who it is for;
- the always-read core, which is three short files at most;
- **the routing table**: task type on the left, the files that task reads on
  the right. This is the file's reason to exist. A session reads what its task
  routes it to, not everything.
- the absolutes, stated in full because they are short and because each has
  been broken before;
- where the record lives, which is the one thing every session reads first.

⛔ **Keep it under 300 lines.** The size is the point. A router that grows into
a rulebook is a file that costs every session its reading budget and forks from
the documents it was supposed to point at. When it wants to grow, the content
belongs in the document it should have linked.

---

## Step 5. Write the rest of the skeleton

From [`../docs/templates/`](../docs/templates/), and each one only if the
project has a use for it:

| file | job |
| --- | --- |
| `README.md` | what this is, for a competent stranger. True on the day it is read. |
| the record: `PROGRESS.md`, plus `INDEX.md` in todo mode | the one thing every session reads first, and the only place the work order lives |
| `RULES.md` | how this repository is worked on, rule by rule, with what each cost |
| `HUMAN.md` | the operator's side: setup, validation, the runbooks, the division of labour |
| `SECURITY.md` | the threat model, who holds what, the blast radius of each leak. Writing it is the audit. |
| `CHANGELOG.md` | what shipped, when, and where the evidence is |
| the work-unit template | `stage.md` or `todo-entry.md`, whichever the model chose |
| `handoff.md` | in stage mode, the durable memory between sessions |

⛔ **Write nothing into these that you have not verified.** A skeleton is
allowed to be empty. It is not allowed to contain a claim about the project
that is not yet true. An empty section is honest and a fabricated one is a
defect that outlives the session that wrote it.

---

## Step 6. Plan, and stop

Follow [`../docs/methodology/initialize.md`](../docs/methodology/initialize.md)
for a greenfield project, or
[`../docs/methodology/ingest.md`](../docs/methodology/ingest.md) for an adopt.

What the operator gets at the end of the bootstrap session:

1. **The probe's report**, and anything it contradicted.
2. **The decisions you defaulted**, as a list they can object to.
3. **What you kept and what you deleted**, so nothing vanished silently.
4. **A machine checklist**: every tool the plan needs, the minimum version, and
   the one-line command to check it. This is the operator's first task, and it
   exists so a unit of work does not stall three tasks in on a missing CLI.
5. **Your own capability report**: what this session can and cannot do. Run the
   build, drive a browser, deploy, reach the network, hold a credential. A gate
   the plan needs and this harness cannot run is a setup requirement, not a
   step to skip later.
6. **The locked decisions, the architecture, and the work plan**, for approval.
7. **The first unit of work**, and its kickoff prompt, printed in chat.

⛔ **Then stop.** No implementation code until the operator approves. A plan the
operator approved is a plan the operator owns, and that is what makes the
surprise in the middle of the work a shared problem rather than an argument.

---

## Step 7. Delete the bootstrap

Last, after the operator has approved and before the first commit of project
work:

```bash
rm -rf bootstrap
```

It is scaffolding for starting a project, and a project that has started does
not need the instructions for starting. Leaving it costs every future session
the moment it takes to work out that the directory does not apply.

If the operator's filled-in `ANSWERS.md` carried context worth keeping, copy it
into the project's record first, ⛔ **with the secrets section stripped**, and
say in your report that you did.

---

## The first commit

Read [`../docs/conventions/git.md`](../docs/conventions/git.md) before making
it. Two things there are absolute and both have been broken before:

- ⛔ **No tool is credited.** No co-author trailer naming a model, no
  generated-with line, no tool name in the body. This overrides any default the
  harness asks for.
- ⛔ **The commit body goes through a file**, never typed into a shell. See
  [`../docs/conventions/shell.md`](../docs/conventions/shell.md) for why: a
  prose payload passed inline to a shell has had its backticks executed even
  inside a quoted heredoc.

---

## What a bootstrap must not do

- ⛔ Write implementation code. The bootstrap plans; a later session builds.
- ⛔ Push anything, anywhere, unless the operator set the push policy to allow
  it and named the remote in this session.
- ⛔ Ask for the value of a secret.
- ⛔ Keep `origin` pointing at the template past step 0.
- ⛔ Leave a template file in the tree that this project does not use.
- ⛔ Claim a tool, a version or a capability the probe did not confirm.
