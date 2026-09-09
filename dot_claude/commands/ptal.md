---
description: Please Take Another Look — a critical review pass on whatever we've been iterating on
---

Take another look at what we've been working on in this conversation, the way you would
review a colleague's CL before approving it. The goal is a real review, not a pat on the back.

Structure the pass like this:

1. **Restate the goal** — one line on what this artifact (code, doc, email, config) is
   actually trying to achieve, so we can catch drift before anything else.
2. **Correctness / risk first** — anything that's wrong, would break, would confuse the
   reader, or creates a foot-gun. This is the load-bearing section; don't bury it under
   style comments.
3. **Gaps and edge cases** — anything unstated, unhandled, or assumed that shouldn't be.
4. **Clarity and structure** — naming, ordering, tone, or organization issues, but only
   ones that materially affect the reader/user, not nitpicks for their own sake.
5. **Nits** — genuinely minor stuff, clearly labeled as optional, kept short.

Rules for the review itself:
- Be direct. If something's wrong, say so plainly — don't soften it into a question unless
  it genuinely is one.
- Don't rewrite the whole thing unless asked; point at the specific spot and say what's
  wrong and why, the way review comments do.
- If it's solid, say so briefly and move on — don't invent issues to fill out the sections.
- If $ARGUMENTS is provided, treat it as a specific focus area for this pass (e.g.
  "$ARGUMENTS: focus on the error handling") and weight the review accordingly, while still
  doing a quick pass over the rest.

$ARGUMENTS
