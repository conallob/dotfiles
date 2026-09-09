---
description: "Please Take Another Look" — re-review whatever's currently under review (PR/MR, code diff, draft email/doc) against prior feedback
argument-hint: "[optional: PR number, file path, or what to re-check]"
---

# /ptal — Please Take Another Look

Re-review the thing currently being iterated on, the way you'd ask a
colleague for a second pass after addressing their comments. Figure out
what kind of artifact is in flight, then apply the right kind of scrutiny.

Arguments (if given): $ARGUMENTS

## Step 1 — Identify what's in review

Look at the conversation, the arguments above, and the working directory to
determine what's being iterated on, in this priority order:

1. **An open PR/MR** — if the current branch has an associated PR, or a PR
   number/URL was passed in, or the user has been discussing one, that's
   the target.
2. **Uncommitted or recently committed code changes** — if there's a dirty
   git diff or recent commits with no PR yet, review the diff directly.
3. **A draft document, email, or design** — a file (Markdown, Google Doc,
   Gmail draft, etc.) that has been discussed or edited earlier in this
   session.

If it's ambiguous, ask rather than guessing.

## Step 2 — Re-review based on artifact type

### Code / PR / MR
- If a PR exists, use the `code-review` skill against the PR's diff (or
  invoke it with the PR number/branch as target). Prefer `medium` effort
  for a routine re-check; go `high` if the diff is large or this is the
  first pass.
- Cross-check against any earlier review comments (Claude Code Review, a
  human reviewer, or your own prior findings in this session): confirm
  each one is actually resolved in the current diff, not just acknowledged.
- Run the `lint-test` agent before declaring it clean.
- Report: resolved items, still-open items, and anything new introduced by
  the latest edits.

### Draft email / doc / design
- Re-read the current draft in full, not just the delta since last time.
- Check it against:
  - Any explicit feedback already given in this session (does the new
    draft actually address each point?)
  - The original goal/audience for the piece (does it still serve that
    purpose, or has scope drifted while iterating?)
  - Clarity, tone, and length appropriate to the medium (a PTAL email
    reads differently than a design doc).
- Flag anything that reads as unresolved, contradictory, or newly
  introduced noise from the edits.

## Step 3 — Report back

Give a short, structured verdict:
- **Resolved**: what prior feedback is now addressed
- **Still open**: what isn't, with a pointer to where
- **New findings**: anything the latest pass surfaced that wasn't flagged before

Don't just say "looks good" — name what you checked. If everything is
genuinely resolved, say so plainly and note it's ready to send/merge/ship.
