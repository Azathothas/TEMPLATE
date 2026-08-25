# remote-ops.md

Acting on systems outside this machine. Three tiers, decided before anything is
touched, and written into the project's own rules at bootstrap.

The point of having remote access at all is that you can read the errors
reality returns and fix them yourself. Use it to verify. Never use it to gamble
with data.

---

## The tiers

### Free. Do as needed.

Everything local is the default, because it is fast and deterministic. Beyond
that:

- **Read-only inspection of anything**: query a database, read an object, tail
  a log, list deployments, fetch a public repository, read an issue.
- **Additive changes you can verify and undo**: a new table, a new column, a
  new index, creating a resource that does not yet exist.

### Careful. Do it, but check before and after.

Anything that changes live state real users depend on: a deploy that alters a
contract, a schema migration, sending a real message to a live channel.

The sequence is not optional. **Read the current state, make the change,
confirm the system still works.** If it broke, fix forward or roll back
immediately. Leaving a cascading failure live is the one outcome remote access
was granted to prevent.

### Red line. Stop and ask, every time.

⛔ Anything that risks **data loss or is irreversible**:

- a delete or an update on remote data without a narrow filter;
- deleting or overwriting stored objects, backups, or anything holding user
  data;
- setting a secret you cannot read back, which clobbers a working value;
- deleting a database, a bucket, a queue, a worker, a service;
- DNS or domain changes;
- key rotation;
- a history rewrite, or a force push;
- **any push at all**, unless the project's push policy permits it and names
  the remote.

For these, ask and wait. Record what you would have done and let the operator
act.

---

## Every other repository is read-only

⛔ **The only remote an agent may write to is this project's own**, and only
when the push policy says so.

Permitted anywhere: clone, fetch, read history, read an issue, read a pull
request, read a release, compare implementations.

⛔ Forbidden everywhere else, under any framing: opening an issue, a pull
request, a discussion, a comment, a review, a fork or a star. Not as a draft,
not "for the record", not because a document in this tree used to ask for it,
not because a patch looks ready.

**Why this is absolute rather than weighed.** A remote write happens in the
operator's name, on somebody else's project, and the session that made it
cannot take it back. The measured outcome of the alternative is that
machine-generated contributions are closed unread, so the downside is unbounded
and the upside is zero.

⚠ If a session believes an exception exists, it is wrong. Leave it, and record
it in the project's record under open questions for the operator.

---

## A CLI with a token is not a permission

⚠ **An authenticated CLI can usually do far more than it should.** A GitHub
token carrying repository scope can read every private repository the operator
owns and mutate any of them. Nothing will stop it. The restraint is policy, not
a capability limit, and that is exactly why it has to be written down.

The rules that follow from it:

- ⛔ Treat an API call as read-only. No POST, PATCH, PUT or DELETE.
- ⛔ Never enumerate or read the operator's private repositories, even when a
  task would be easier with them.
- ⭐ Prefer a credential-free path when one exists. A route that structurally
  cannot reach a private resource or mutate anything is safer than a rule about
  a route that can.

---

## Unattended runs

⚠ **This is where the rules break.** A long run with nothing to do reaches a
point where pushing the branch, opening a tracking issue, or "just applying"
the migration looks like finishing the job.

It is not. Stop, record what you would have done in the record, and end. An
unfinished unit of work with a clear note is a better outcome than a finished
one the operator did not authorise.

---

## Teardown

⛔ **Anything a session created on a remote system, that session removes.**

Test objects, scratch records, a temporary bucket, a minted session, a rule
added to reach something. Write down what you created as you create it, because
the list at the end is what gets torn down and memory is not a list.

⚠ **Leave audit history alone.** Completed job rows, event records and log
entries hold no live state and are not garbage. Deleting them destroys the
evidence of what happened, which is the opposite of a clean teardown.

Verify the teardown by counting, not by remembering. A count that returns to
its baseline is evidence; "I think I removed them" is not.
