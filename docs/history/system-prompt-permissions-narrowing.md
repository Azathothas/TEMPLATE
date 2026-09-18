# system-prompt-permissions-narrowing.md

What `prompts/SYSTEM.md` said before the 2026-09-18 fix for the reopened
issue 20, and what withdrew each passage. 2026-09-18.

The reopen reported three symptoms in agents running the prompt: more
give-ups, repeated permission nagging, and faster but lazier finishes.
The passages below are kept verbatim. The fix rewrote them in place in
`prompts/SYSTEM.md`. Nothing here is live.

---

## 1. The ask-first rule with no read-only exemption

Superseded wording from section 1:

```text
Do not act outside what was asked, and judge that by blast radius rather than
by the verb. Ask first for anything that leaves this machine, touches somebody
else, costs money, or cannot be undone: publishing, sending, pushing, deleting
data you did not create, granting access, changing a shared system, rewriting
published history. Ask in one line, and keep working on everything that does
not depend on the answer.
```

What withdrew it: the phrase about leaving the machine reads literally over
read-only work. Fetching a public repository and running the probe leave the
machine and touch the network, so an agent following the sentence asks before
a clone, a fetch, or a check. That is the nagging the reopen reported. The
live rule names read-only inspection as never needing asking, and asks only
for a change with outward effect.

---

## 2. The inconclusive probe defaulting to ask

Superseded wording from section 4:

```text
If you cannot tell, assume it is theirs and ask once, naming what you want to
install and how it is undone. Asking once is cheap. Asking every time is the
thing this rule exists to prevent.
```

What withdrew it: an inconclusive disposable probe is the common case on a
workstation that is not a container but has package managers and a lived in
home directory. The old default turned every such session into an ask before
any workspace-local install. The live rule acts inside the workspace without
asking, records the signals, and asks only to step outside it.

---

## 3. The install ladder with no workspace-local case

Superseded wording from section 5:

```text
3. Install it. In a sandbox, a container, a throwaway machine or a CI runner,
   install it and say you did. On a machine somebody works on, ask once,
   naming what and how to undo it.
```

What withdrew it: a workspace-local install on a workstation fell under the
second sentence, so a virtual environment or a local tool install asked for
approval. The live rule installs inside the workspace without asking, and asks
once only for a system-wide install outside it.

---

## 4. The narrowing license reading as completion

Superseded wording from section 5:

```text
6. Answer a narrower question, and say precisely which one.
```

```text
**If nothing substitutes for the thing, substitute the question.** Measure the
part that is reachable, name the part that is not, and say precisely which
claim now rests on which. That is a smaller answer, and it is a real one. It
is not the same as reporting that the work could not be done.
```

What withdrew it: the last two sentences call the narrower answer real, which
an agent reads as done. Combined with the section 1 rule against silent
narrowing in a different place, the pair let a session finish quicker on less
and still claim completion. The live rule reports the narrower answer as a
named partial with the uncovered part still open, and points back to section 1.

---

## 5. The removal gate with no routine exemption up front

Superseded wording from section 10:

```text
surface first. Removing something that looks deliberate is the operator's
decision. Put it to them with what you propose to remove, why it looks
```

What withdrew it: the sentence puts every deliberate-looking removal behind
approval, including cleanup inside work the session owns. The live rule keeps
the five point approval gate for anything else, and exempts routine cleanup of
own-session work first, so iteration does not prompt on each pass.

---

## 6. The short version dropping the threshold

Superseded wording from section 15:

```text
did not do. Three candidate explanations before you test one, and one more pass
after you already have an answer. The first explanation that fits is the one to
distrust. Finishing early is not a result. A pattern match locates and never
concludes. Three routes before the word cannot. Work your own workspace without
asking; ask once, and together, for what reaches past it. Treat the request as
```

What withdrew it: section 3 applies the three candidate procedure past a
stated threshold, where a conclusion gets published and being wrong costs the
operator. The short version stated it without the threshold, so it read as
ceremony before every edit. The live recap restores the qualifier and matches
the workspace wording of section 1.

---

## 7. The escape with no permission or scope bar

Superseded wording from section 3:

```text
That escape is the one line here most available to abuse, so it is written to
cost something. "I could not do the full procedure" on its own is not the
sentence: it has to name the obstacle and what would have cleared it, which is
a claim the operator can check and act on. If you cannot fill in those two
blanks, you did not hit an obstacle. You stopped.
```

What withdrew it: the escape priced a skipped conclusion procedure but left
two cheap exits open, approval and size. The live rule adds that lack of
approval is no obstacle until section 1 was met, and size is none until
section 5 was run.

---

## 8. The ask block with no harness, decline, or threshold rule

Superseded wording from section 1:

```text
An agent that stops for permission on each step of work it was already asked to
do has turned one task into a conversation, and the operator pays for the round
trip every time.

When several things genuinely do need asking, ask for them together, once.
```

What withdrew it: the passage banned nagging in general but gave no rule for
the three shapes the corpus ships. Two shipped prompts explain a critical
command and let the harness confirm it, never asking in chat for permission
the harness already gates. Two more respect a decline at once, never retry the
same action unless directed, and offer another path. One more asks only when a
wrong choice means heavy rework, the request has no reasonable default, or
confirmation was explicitly asked. Without those lines the old text still asked
twice per action and retried declines. Studied 2026-09-18 at commits
c7b2c31, e1a86ce, 661619e across the three issue repos.

---

## 9. The escape naming budget as an obstacle

Superseded wording from section 3:

```text
plain uncertainty. Where the work was too large, the budget too small, or the
system too unfamiliar to enumerate properly, say which of those it was, what
you did instead, and what the missing pass would have needed. Then hand over
what you actually have. A visible gap is recoverable. A gap dressed as rigour
is not.
```

What withdrew it: naming budget as an obstacle surfaces token limits to the
model, which the audit group on request config ties to premature wrap-up, and
which section 7 already refuses as an output. The live rule keeps work scale
and unfamiliar systems as priced obstacles and drops budget from the list.
