# system-prompt-sweep.md

What was read before `prompts/SYSTEM.md` was written, what was measured rather
than believed, and what this sweep did not establish. 2026-09-18.

---

## ⛔ What this did NOT establish

Read this before the findings, not after.

- **The corpus was indexed in full and read in part.** Its whole file list was
  taken: **493 files, 16.9 MB, across 22 top-level directories**, of which
  Anthropic is 311 files and OpenAI 87. Thirteen of the coding-agent prompts
  were fetched, four were read end to end, and the rest were searched by theme.
  ⛔ **Nothing outside the coding-agent subset was read at all**, which leaves
  the image, search, voice and consumer-assistant prompts untouched.
- ⚠ **A first pass over eight files was thrown away and redone.** It measured
  where directives sit and stopped, which is a structural fact about the text
  rather than a study of what the text asks an agent to do. The operator
  rejected it in those terms. The numbers from it survive, because position was
  the one thing it measured properly.
- **Nothing here measures whether a prompt WORKS.** Every number below
  describes the shape of text that shipped. Whether that shape produces better
  behaviour is a claim this sweep cannot make, because it had no way to run a
  model against a variant and compare.
- **No adversarial reading.** The corpus is a third-party collection of
  material its publishers did not release. Whether each file is genuine, whole
  and current was not verified, and a fabricated or edited entry would be
  invisible to the measurement below.
- **The corpus is not kept in this tree**, so every number here is reproducible
  only by re-fetching it. The commands are in the last section.
  [`../methodology/research.md`](../methodology/research.md) section 3.4 has
  the rule and names this exemption: a repository whose job is to be copied
  cannot carry somebody else's tree.
- ⛔ **Assume claims remain that are wrong.**

---

## The references, as read

| what | at | read |
| --- | --- | --- |
| `asgeirtj/system_prompts_leaks` | `c7b2c31df51e` | 2026-09-18, eight files, listed below |
| `can1357/oh-my-pi`, the system-prompts skill | `c101452bb5a6` | 2026-09-18, in full |
| `earendil-works/pi`, the deslop prompt | `5009d0608c26` | 2026-09-18, in full |

⚠ **The operator named four links and two were the same repository**, so this
is three references rather than four.

⛔ **No text from any of them is reproduced in
[`../../prompts/SYSTEM.md`](../../prompts/SYSTEM.md).** The corpus is somebody
else's proprietary writing, published without their consent, and this
repository is public. What transferred is mechanism, which is what
[`../methodology/research.md`](../methodology/research.md) says transfers
anyway.

---

## ⭐ The claim that was checked, and half of it did not survive

One reference states that critical constraints belong at the **start and the
end** of a prompt because the middle of a long context degrades, and that
prescriptive prose uses **uppercase** keywords in the RFC 2119 style.

Both are claims about a corpus that is public, so they were measured instead of
believed. The instrument counts directive lines, buckets each by its position
in the file as a decile, and reports the share in the first and last decile
against the 20% a uniform distribution would give.

Measured on one Windows 11 Pro 10.0.26200 machine under Git Bash 5.3.15 on
2026-09-18, over eight prompts from six vendors, 705 directive lines in total:

| | share of directive lines | uniform would be |
| --- | --- | --- |
| ⭐ first two deciles | **47.1%** | 20% |
| last two deciles | 17.6% | 20% |
| uppercase keywords | 24.3% of directives | - |

| file | lines | directives | first two deciles | last two |
| --- | --- | --- | --- | --- |
| `Anthropic/claude-opus-5.md` | 2934 | 164 | 76 | 21 |
| `Anthropic/claude-sonnet-5.md` | 2942 | 154 | 72 | 23 |
| `OpenAI/gpt-5.5-thinking.md` | 1450 | 181 | 92 | 42 |
| `OpenAI/gpt-5-thinking.md` | 951 | 115 | 65 | 16 |
| `OpenCode/opencode.md` | 253 | 40 | 12 | 10 |
| `Google/gemini-cli.md` | 190 | 25 | 5 | 4 |
| `xAI/grok-4.md` | 139 | 14 | 5 | 6 |
| `Google/gemini-3-pro.md` | 135 | 12 | 5 | 2 |

⭐ **Front-loading is strongly supported and end-loading is not.** Shipped
prompts put roughly two and a half times the uniform share of their directives
in the opening fifth, and slightly **less** than the uniform share in the
closing fifth. Seven of the eight put more directives in the first two deciles
than in the last two; the exception is `grok-4`, at five against six, on
fourteen directives total.

⚠ **So the advice to repeat the critical rules at the end is not what the
corpus does.** `SYSTEM.md` follows the measurement: its rules are in section 2,
inside the first fifth, and its closing recap is six lines rather than a
restatement.

⭐ **Uppercase keywords are the minority practice.** Three directive lines in
four use ordinary lowercase prose. The reference presents all-caps as the house
convention, which it is entitled to do; it is not what shipped prompts
predominantly do, and this one does not either.

⚠ **What the numbers cannot say.** A directive line was identified by keyword,
so a rule phrased without one is invisible, and a keyword inside an example or
a quotation is counted. Both biases inflate the totals rather than the ratio,
and the ratio is what the finding rests on. The line counts include tables and
fenced blocks.

---

## ⭐ What the corpus actually teaches, which the position measurement does not

⛔ **The second reading was for MECHANISM rather than shape**, and it is where
`SYSTEM.md` got most of its content. Every row below is a rule a shipped prompt
states, restated here in this repository's words. ⚠ None of them is quoted:
section 3.5 of [`../methodology/research.md`](../methodology/research.md) is why.

| what several of them do | where it landed |
| --- | --- |
| forbid apologising as a reflex, and ask for the correction instead | section 6 |
| forbid over-validation of the operator by name, including the phrase agents reach for most | section 6 |
| put truthfulness above agreeing with the operator, in as many words, and instruct the agent to disagree when the evidence says so | section 7 |
| forbid explaining WHY something was declined, on the grounds that it reads as preachy | section 6 |
| refuse a check built from the assumption under test, and require an independent oracle | section 2 |
| forbid re-running a refused check with the guard skipped, forced or disabled | section 4 |
| treat something else found broken as a FINDING for the report rather than as new work | section 12 |
| ⭐ treat the request as an exhaustive checklist, giving error and edge clauses the weight of the happy path | section 1 |
| forbid narrowing a failing test run until it passes | section 9 |
| forbid marking work complete because a budget is nearly spent | section 6 |
| name the interactive-command traps concretely: the pager, the editor, the prompt, the watcher | section 10 |
| build a large file incrementally rather than in one write | section 9 |
| treat files the agent did not create as the operator's property | section 9 |
| keep an operator correction active until they lift it | section 1 |
| calibrate explanation depth to the reader without announcing it | section 7 |
| adapt immediately and without defensiveness when redirected | section 7 |

⚠ **Two things the corpus does NOT support, and they were left out.** Nothing
read here tells an agent to perform enthusiasm, and nothing read here asks for a
closing summary of work the operator just watched. Both are common in practice
and neither is instructed, which suggests they are model habits rather than
prompt requirements. ⛔ So `SYSTEM.md` forbids them on this repository's own
judgement rather than on the corpus, and that distinction is recorded rather
than blurred.

---

## Verdicts

| reference | verdict | what transferred |
| --- | --- | --- |
| `system_prompts_leaks` | ⭐ **adopt, as an oracle.** Its value here was not as a source of wording but as ground truth against which another reference's advice could be checked. | the front-loading of section 2, and the decision not to end-load |
| `oh-my-pi`, system-prompts skill | **adopt in part.** Density, one claim per bullet, naming a verification path rather than saying "review your work", and the anti-pattern that a prohibition without a positive alternative processes worse than an instruction. | the shape of sections 6 and 11 |
| | ⚠ **and refused in part**: all-caps keywords and its tag vocabulary. Both are house conventions for one harness, and this repository already has a register. | |
| `pi`, deslop prompt | ⭐ **adopt one mechanism, refuse the thesis.** | the **approval gate**: name what you propose to remove, why it looks unnecessary, what could break, the simpler replacement, and your recommendation, one decision at a time. It is section 9. |
| | ⛔ Its removal thesis was **refused on the operator's stated position**: cutting a guard, a test or an error path to reduce line count trades a small saving now for an incident later. ⭐ The gate is the half that survives, and it is the half that guards exactly that failure. | |

⚠ **The third row is the useful one, and it is a worked example of adopting an
idea rather than an architecture.** A reference the operator supplied argued
for something the operator disagrees with. The mechanism inside it was still
the best answer to a different question, and separating the two was the whole
value of reading it.

---

## The instrument

⚠ **It is not committed to this repository**, because it measures somebody
else's corpus and no project started from this template would ever run it. It
is kept here verbatim instead, so that every number above can be reproduced.
[`../methodology/research.md`](../methodology/research.md) is the rule it
would otherwise follow.

To reproduce: fetch the eight files named in the table into one directory,
write the script below beside them, and run it with that directory as its one
argument.

```text
#!/bin/sh
# measure-prompts.sh - where do directives sit in a real system prompt, and do
# real prompts use all-caps RFC 2119 keywords?
set -u

DIR="${1:-.}"
[ -d "$DIR" ] || { printf 'measure-prompts: no such directory: %s\n' "$DIR" >&2; exit 2; }
command -v awk >/dev/null 2>&1 || { printf 'measure-prompts: awk not found\n' >&2; exit 2; }

printf 'measure-prompts  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'host: %s\n\n' "$(uname -srm)"
printf '%-34s %7s %7s %7s %7s %7s\n' file lines direct edge% upper lower

for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  LC_ALL=C awk -v F="$(basename "$f")" '
    function isdir(s) {
      return (s ~ /\<(MUST|NEVER|SHOULD|REQUIRED|SHALL|ALWAYS|DO NOT|MUST NOT)\>/ \
           || s ~ /\<(must|never|should|always|do not)\>/)
    }
    { if ($0 ~ /[^ \t]/) { n++; L[n] = $0 } }
    END {
      if (n < 20) { exit }
      d = 0
      for (i = 1; i <= n; i++) {
        if (!isdir(L[i])) continue
        d++
        b = int(((i - 1) * 10) / n) + 1
        if (b > 10) b = 10
        B[b]++
        if (L[i] ~ /\<(MUST|NEVER|SHOULD|REQUIRED|SHALL|ALWAYS|DO NOT|MUST NOT)\>/) up++
        else low++
      }
      if (d == 0) { printf "%-34s %7d %7d %7s %7s %7s\n", F, n, 0, "-", "-", "-"; exit }
      edge = (B[1] + B[10]) * 100 / d
      printf "%-34s %7d %7d %6.1f%% %7d %7d\n", F, n, d, edge, up + 0, low + 0
      printf "    deciles:"
      for (k = 1; k <= 10; k++) printf " %d", B[k] + 0
      printf "\n"
    }
  ' "$f"
done
```

⚠ **It has no expectation flag and no non-zero exit**, which
[`../methodology/research.md`](../methodology/research.md) asks for and
which would have turned it into a standing check. It was not given one because
nothing in this repository would run it. ⭐ A project that repeats this
measurement should add one.
