# prose-register.md

What `docs/conventions/prose.md` used to open with, and why naming a character
turned out to be the wrong way to state the rule. Retired on 2026-09-18.

---

## The retired wording

Kept verbatim. It was the first section of the page, so it was the first thing
every agent read about how to write here.

> ## The rule
>
> Short sentences. No em dashes. No marketing adjectives. No emoji beyond the
> five defined below, and only three of those belong in prose. Present tense.
> Every claim backed by a command a reader can run or a path a reader can open.

⚠ **Five of the six items are prohibitions and every one of them names a
symptom.** The page did name the standard those symptoms come from, ASD-STE100,
and it named it in the second-to-last section of a 313-line file. A reader
following the router arrived at the prohibitions and stopped.

---

## ⭐ What withdrew it

⛔ **Banning the character taught agents to respell it.** Reported by this
repository's operator on 2026-09-17: agents reaching for an em dash, finding
the character refused by a check, and writing a run of hyphens or a comma
instead. The check stayed green on every run. Not one sentence got shorter.

⚠ **The rule was satisfied and the defect was untouched**, which is the same
shape this page already records about the marker allowlist: an agent kept
strictly to the five permitted characters and spammed them until the documents
were unreadable, because keeping to the list was read as compliance and nothing
counted how many. Both are what a prohibition does when it names a symptom
rather than the construction.

## What replaced it

The register leads the page now, and the dash rule names the sentence rather
than the character: a sentence that needs a dash is a sentence to split, and
every spelling of the dash is the same defect.
[`../conventions/prose.md`](../conventions/prose.md) carries it.

⭐ **The respelt dash is checked, and the third spelling is not.**
`scripts/common/check-markers.sh` refuses a run of hyphens in markdown prose,
in both halves, mutation-proved in each. A comma splice carrying the same
parenthetical is the commonest of the three and no guard can reach it, so the
page says so beside the rule instead of leaving a green run to be mistaken for
a well-written page.
