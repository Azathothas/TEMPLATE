# research-merge.md

Why `references.md` and `experiments.md` were two documents, and why they are
one now. Merged into `research.md` on 2026-09-18.

---

## The retired position

Both files opened by saying they were separate on purpose. Kept verbatim, from
`references.md`:

> ⚠ **This is about studying somebody else's code.** Running your own
> measurements is `experiments.md`, and a project doing serious work usually
> needs both. They are separate because they answer to different rules: a sweep
> owes provenance for code it did not write, and an experiment owes a
> repeatable command and a negative result.

And from `experiments.md`:

> ⚠ **Not the same job as `references.md`.** That is studying somebody else's
> code and it owes provenance for work you did not do. This is producing your
> own numbers and it owes a command somebody else can re-run. A project doing
> real work usually needs both, which is why they are two files.

⭐ **The distinction those paragraphs draw is correct and it survives.** It is
now the table at the top of `research.md` rather than a reason for two files.
Two jobs with different obligations do not require two documents; they require
the obligations to be stated separately, which a section heading does.

---

## What withdrew it

⛔ **The operator was assembling the reading list by hand, one link at a time.**
Reported on 2026-09-17. The cost was not theoretical: handing a session one of
the two meant it never learned the other existed, and handing it both meant
the operator had to know in advance which halves of the job the session would
turn out to need.

⚠ **A first attempt made it worse.** A `research.md` was written that pointed
at both files rather than containing them, which is one more link to paste
rather than one fewer. The operator rejected it in the same terms: a document
that must be given alone cannot delegate the answer.

⚠ **There was a second, weaker reason to merge, and it should be named rather
than hidden.** A standalone document restating two live documents fails
`check-one-home`, which refuses a sentence of twelve words or more appearing in
two places. Merging removes the duplication instead of exempting it. That is a
consequence of doing the right thing rather than the reason for doing it, and
the check would have been the wrong thing to change.

---

## What replaced it

One document, [`../methodology/research.md`](../methodology/research.md),
covering the boundary between research and implementation, studying somebody
else's project, taking your own measurements, the proof of concept, the gate
when the deliverable is a finding, when to stop, and what the unit hands over.

⚠ **What the merge cost.** The bootstrap could previously keep one of the two
and delete the other. It can no longer, so a project that only ever takes its
own measurements now also carries the sweep procedure. That is about two
hundred lines a project does not need, against an operator who no longer has to
know which half a session will want. ⭐ The trade was made deliberately and it
is the kind that should be re-opened if anybody finds it wrong.

⚠ **Section numbers moved.** `references.md` section 4 is now `research.md`
section 3.4, and every inbound link was repointed in the same change, including
the two halves of `mine-repo`, which name the section in a refusal message.
