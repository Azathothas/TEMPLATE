# history

Superseded wording from this repository's own documents and scripts, kept
verbatim so a future session can find out why a rule is what it is instead of
re-deriving it wrongly.

⭐ **This is the template's own history, not a skeleton.**
[`../templates/HISTORY.md`](../templates/HISTORY.md) is the skeleton a project
receives; this directory is where THIS repository's retired text goes.
[`../methodology/history.md`](../methodology/history.md) is the rule both
follow.

⛔ **A bootstrap deletes this directory** and creates the project's own empty
one from the skeleton. A project inheriting the template's history would start
life with a record of decisions that were never its own.

---

## What is here

| file | what it holds |
| --- | --- |
| [`twins-and-scripts.md`](twins-and-scripts.md) | the retired rule that only the environment probe needed a PowerShell twin, and the removed licence and commit helpers |
| [`upstream-tool-shape.md`](upstream-tool-shape.md) | what this repository used to say about the shape of a tool it does not ship, and why upstream had to be the one to notice |
| [`prose-register.md`](prose-register.md) | the prohibition-first opening of the prose rules, and what banning a character taught agents to do instead |
| [`research-merge.md`](research-merge.md) | why studying somebody else's code and taking your own measurements were two documents, and what merging them cost |
| [`system-prompt-sweep.md`](system-prompt-sweep.md) | what was read before `prompts/SYSTEM.md` was written, the measurement that refuted half of one reference, and the instrument that took it |
| [`system-prompt-permissions-narrowing.md`](system-prompt-permissions-narrowing.md) | what the reopen of issue 20 withdrew from the prompt: the ask-first, narrowing, and recap wording that nagged, gave up, and finished early |

---

## Claims this repository has published and later withdrawn

⭐ [`../methodology/history.md`](../methodology/history.md) asks for this list on
the front page, because a reader who trusts a document without checking it
trusts sentences that are wrong.

| claim | where it was | what withdrew it |
| --- | --- | --- |
| "Every other check here is POSIX sh alone, deliberately" | `scripts/common/check-twins.sh` header | a native PowerShell session on one Windows 11 machine, 2026-08-25, had no `sed` and resolved `sort` to `Sort-Object`. Every check gained a twin, and the header kept the retired sentence for as long as it took a maintenance session to read it. [`twins-and-scripts.md`](twins-and-scripts.md) |
| "The pair was proved instead by running both halves and both routes against one target, which is stronger evidence" | `scripts/README.md`, about `mine-repo` | it was not stronger. That comparison ran against a target whose comment bodies had balanced brackets, and the page joiner's defect was invisible to it. A consumer found it. `mine-repo --selftest` replaced the claim with a comparison that runs on every gate. |
| "It is two products now, and a caller gets the compiled one by default" | `docs/containers.md`, about `wsl-toolkit` | upstream deleted the PowerShell product and its launcher. The correction came from upstream's own register of who depends on it, not from anybody here. [`upstream-tool-shape.md`](upstream-tool-shape.md) |
| "`write-file` writes or patches a file without the shell touching the payload" | `docs/agent-tooling.md` | the tool still exists and is no longer the answer. `text-tool` replaced it. [`upstream-tool-shape.md`](upstream-tool-shape.md) |
| "When the target is not a Windows program, the rewrite is corruption" | `docs/conventions/shell.md` section 7 | it is the ARGUMENT that decides, not the callee's platform. `gh.exe` is a Windows program and was corrupted anyway. Re-measured on this repository's development machine on 2026-09-18; the row is now in section 7. |
| "No em dashes", as the second thing said about how to write here | `docs/conventions/prose.md` | naming the character taught agents to respell it, and every run stayed green. [`prose-register.md`](prose-register.md) |
