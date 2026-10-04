---
name: design-doc-writing
description: |
  Help write a Product Requirements Doc (PRD / proposal) or a Detailed Design doc.
  Use when: the user wants to draft, outline, restructure or prepare for review a
  PRD, proposal, design doc, or technical design. Covers choosing the right
  document type, scoping (problem statement, goals, non-goals), Alternatives
  Considered, Detailed Design, background, and getting the doc to the right
  reviewers.
user-invocable: true
---

# /design-doc-writing — Write a PRD or Design Doc

Guide the user through writing either a PRD (proposal) or a full design doc.
For reviewing someone else's doc, use `/design-doc-reviewing` instead.

## Step 1 — Pick the document type

- **PRD / proposal**: starts a design process by defining a problem statement
  and some ideas. Use it to:
  - decide whether a problem is worth exploring further, or fail fast
  - reach consensus with multiple stakeholders at several points in the design
  - delegate a full design doc to somebody else (e.g. a new joiner)
- **Detailed design doc**: describes the chosen solution precisely enough to
  implement and review.

Never use the PRD template for a full design doc; reviewers will send it back.
Prefer a template with a TL;DR, Context and team-scope metadata if one is
available, adding any standard headings it lacks.

Fill in the metadata first: authors, reviewers, approvers, status, a short
link/alias for the doc.

## Step 2 — Write in this order

1. **Scope first, always**: problem statement, goals, **non-goals**. Being
   explicit about what is out of scope is as useful as the goals.
2. **Alternatives Considered**: jot down each major technology decision as it
   arises; later flesh each out with pros and cons and why the choice was made.
   - Alternatives must be for *specific decisions within the design*, not a
     single end-to-end alternative solution to the whole problem.
3. **Detailed Design** (design docs only), concisely:
   - Describe all interface changes exactly and unambiguously.
   - Formally describe algorithms, semantics, edge cases and exceptions.
   - Be clear and open about what is missing, *and why*.
   - Where a decision's rationale isn't obvious, point at the relevant
     Alternative Considered or a brief footnote.
   - Only include implementation detail needed to understand the design.
4. **Background** last, to give reviewers the context they need.

**Be concise.** Use structure (headings, bullets, tables, links) and
formatting (monospace, bold, italics) to convey meaning in fewer words.

Required sections: design docs need Background, Detailed Design and
Alternatives Considered; project plans need an explicit Risks section.

## Step 3 — Prepare for review

- Sending a partially written doc is fine if clearly marked WIP and early
  feedback is what's wanted.
- Pick **2–3 approvers** (collaborators and leads for the problem space) plus
  reviewers (subject matter experts and peers). If no SME is known, ask a tech
  lead to help find one.
- Share with them; add relevant teams as commenters, set visibility per the
  organisation's data policy, file it somewhere discoverable (shared drive /
  docs index).
- If reviewers can't find time, schedule a meeting so they can give the doc
  undivided attention.
- Work through discussions with named reviewers and approvers. Comments from
  others are helpful but non-blocking.

## Self-check before sending

- Would someone new to the team make sense of this in 12+ months?
- Are scope, goals and non-goals explicit?
- Does every non-obvious design decision trace to an alternative or rationale?
- Is the design amenable to prototyping or a phased migration?
- Have you researched existing in-house building blocks, rather than assuming
  greenfield?
