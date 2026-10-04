---
name: design-doc-reviewing
description: |
  Review a Product Requirements Doc (PRD / proposal) or a Detailed Design doc.
  Use when: the user asks for a review of, or feedback on, a design doc, PRD,
  proposal or project plan, or wants a reviewer checklist. Covers choosing
  reviewers, review fundamentals, evaluating Alternatives Considered and
  Detailed Design, and handling nits and wordsmithing without blocking authors.
user-invocable: true
---

# /design-doc-reviewing — Review a PRD or Design Doc

Review the doc the user points to (file, link, or pasted text). To write one,
use `/design-doc-writing`.

A reviewer balances **not blocking the author** against **giving actionable
feedback**. Blind LGTMs that favour speed over substance do long-term harm.

## Process norms

- Reviewer vs approver is a function of your organisational role, authority and
  subject-matter expertise, not of the doc's sharing settings.
- Only approvers who can delegate technical direction (managers, tech leads)
  may defer review until the details solidify, then do a quick pass to approve.
- Give technical direction **early** to prevent U-turns during design or
  implementation. Mind review latency, but time invested in the design
  typically saves more time in implementation.
- Apply code-review etiquette (mentoring, review speed) to documents.
- For a large doc or a busy reviewer, propose a meeting for higher-bandwidth
  discussion.

## Checklist

### Reviewers
- Is the reviewer set right and diverse enough to limit bias?
- Has an appropriate subject matter expert been asked? If they only need
  certain sections, are those tagged?
- Do you feel qualified? If not, help find someone who is.

### Fundamentals
- Is scope clearly and explicitly defined?
- Is there a clear problem statement and clear requirements (where
  applicable)? Are they met?
- Is all relevant context captured? Test: will this make sense to a new joiner
  in 12+ months? If it were code, what comments would you ask for?
- Does it use the right template and sections? Design docs: Background,
  Detailed Design, Alternatives Considered. Project plans: Risks Identified.
- See an open comment thread you agree with? +1 it rather than piling on.

### Alternatives Considered
This section must show the problem space was actually researched, and make the
trade-offs transparent.
- No problem is truly greenfield; existing in-house building blocks will
  nearly always apply somewhere.
- Is any alternative dismissed as "can't be done" on the basis of omissions or
  stale information? Challenge that assumption and encourage the author to
  confirm with the owning team.
- Alternatives carried over from earlier designs should be refreshed so the
  trade-offs still hold.

### Detailed Design
- Are larger solutions broken into smaller components?
- Does it reuse existing technology, or justify reinventing the wheel?
- Does it allow prototyping and/or phased migration?
- Are low-level semantics explicit where they matter?
- Are obvious edge cases, failure modes and bottlenecks covered?
- Is there an alternative with more pros and fewer cons than the chosen one?

## Nits and wordsmithing

- Prefix minor feedback (spelling, grammar, small factual fixes) with `Nit:` or
  `Optional:` so the author can tell what needs discussion from what can be
  applied mechanically.
- Substantive feedback first, or in the same pass. Nits-only in a first pass
  reads like an LGTM-with-comments; **if nits are all you have, say LGTM with
  comments** to unblock the author.
- Wordsmithing depth follows audience: team-internal docs, nice-to-have and
  non-blocking; cross-team docs, enough to remove ambiguity, so can block.

## Output format

Group feedback as: **Blocking** (substantive), **Questions**, **Nits**
(prefixed). End with an explicit verdict: approve, LGTM with comments, or
changes needed.
