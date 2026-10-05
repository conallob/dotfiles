---
name: design-doc-writing
description: |
  Help write a Product Requirements Doc (PRD / proposal), a High-Level Design
  (HLD) or a Detailed Design doc.
  Use when: the user wants to draft, outline, restructure or prepare for review a
  PRD, proposal, HLD, architecture proposal, technology selection, build-vs-buy
  comparison, design doc, or technical design. Covers choosing the right
  document type, scoping (problem statement, goals, non-goals), Alternatives
  Considered, Detailed Design, background, and getting the doc to the right
  reviewers.
user-invocable: true
---

# /design-doc-writing — Write a PRD, HLD or Design Doc

Guide the user through writing a PRD (proposal), an HLD or a full design doc.
For reviewing someone else's doc, use `/design-doc-reviewing` instead.

## Step 1 — Pick the document type

- **PRD / proposal**: starts a design process by defining a problem statement
  and some ideas. It serves one of two purposes:
  - **Explore and fail fast**: test an idea and stop early if it is not worth
    pursuing, before anyone invests in a full design.
  - **Set direction and delegate**: fix the direction, then hand the full
    design task to someone else, usually a more junior team member.
- **HLD (high-level design)**: lets a leader set a direction without going into
  the weeds of one or more implementation details. It is a short (3-4 page)
  doc that lets a reader decide quickly whether a proposed direction is right,
  with researched alternatives and explicit trade-offs. Use it for technology
  selection, build-vs-buy, or justifying a tool or platform. It is not a spec.
  **Follow the HLD section below instead of Steps 2-3.**
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

# HLD workflow

An HLD exists so a leader can set a direction without going into the weeds of
implementation details, and so a reader can decide quickly whether that
direction is right. It is not a spec. The usual failure modes are drafts that
are too long, too deep into implementation, and hard to skim, so draft tight
from the first pass instead of cutting later.

Differences from the PRD / design doc guidance above:

- Alternatives Considered here are the **whole candidate solutions** (products,
  platform-native approach, custom build), compared against the same
  requirements. The "specific decisions, not end-to-end alternatives" rule in
  Step 2 applies to detailed designs only.
- Draft the whole doc at target length (below) rather than scope-first.
- Self-check and review preparation (Step 3) still apply once the doc is done.

Stages: 1. Intake, 2. Research, 3. Draft, 4. Iterate, 5. Verify.

## 1. Intake

- **Template first.** If the user links or names a template, use it and keep
  its section order. For a Google Doc template, copy it with the Drive
  connector and fill the copy; never edit the original. Read
  `references/google-docs-mechanics.md` before the first Drive or Docs call.
  With no template, use `references/hld-structure.md`.
- **Use the user's problem statement and requirements as given.** Number the
  requirements so the comparison table can reference them. Do not invent
  requirements; do mark which are v1 versus later, functional versus
  non-functional (e.g. SSO), and nice to have. Users reclassify these during
  review, so keep the classification easy to change.
- **Named alternatives are mandatory.** If the user names one to research, it
  gets a full entry.
- Ask at most one clarifying question, and only if the answer changes the
  research. Otherwise state the assumption in the doc and in your reply.

## 2. Research

Search each candidate separately, plus one pass per hard requirement. Prefer
primary sources (vendor docs, release notes, repositories) over comparison
blogs, and cite them inline. Always check:

- **Editions and tiers.** Open source versus paid or hosted editions are
  different alternatives. Compare them separately and say which one a claim
  applies to.
- **Per-requirement fit.** For each requirement, what each candidate does
  natively, through plugins or extensions, and not at all. Nice-to-haves still
  get checked.
- **User recollections.** When the user says they remember a feature, search
  for it before agreeing or disagreeing. Report what exists, what is adjacent
  (e.g. a write-only ingestion path versus a read API), and what you could not
  confirm.
- **Non-product alternatives.** Include the platform-native approach and a
  custom build, even if you expect to reject them.
- **Conflicting or thin evidence.** When sources disagree (a license, a
  version), say so in the doc and make it an open question. Label secondhand
  claims. Non-public pricing is a finding, not a gap to fill with guesses.

Never contact vendors, send enquiries or sign up for anything unless the user
asks. If an enquiry is the next step, offer to draft it, and note any
negotiating or signalling cost of enquiring as an open question for the user.

## 3. Draft

Target 3-4 pages including all alternatives: roughly 1,600-2,000 words plus the
table. Pageless docs cannot be measured, so estimate from word count and say so.
Section details are in `references/hld-structure.md`.

- **Goals and Non Goals:** short bullets. Non goals stop scope creep and record
  deliberate deferrals. "The design must not block X" is the right phrasing for
  something out of scope but anticipated.
- **Problem statement:** the user's wording, tightened, then the numbered
  requirements.
- **Design thoughts:** proposed direction (one paragraph, including what a
  proof of concept must still prove), architecture bullets, data model,
  delivery phases, open questions. Stay at HLD level; debates such as read
  versus write APIs belong in a later detailed design.
- **Comparison table:** requirements as rows, candidates as columns, cells of a
  few words. Number rows to match the requirements list and add non-functional
  rows (e.g. SSO) at the end. Write "Define ourselves" or "Not verified"
  instead of leaving cells vague. Drop rows that do not discriminate.
- **Alternative sections:** a heading, one or two sentences of description with
  key links inline, then two top-level bullets, **Pros** and **Cons**, each
  with terse sub-bullets, one point each. List length is the at-a-glance signal
  of whether an alternative is worth pursuing, so split compound points and do
  not pad either side. Put each link on the first bullet that makes the claim
  it supports. No separate references section.

Writing style: plain, direct sentences; no filler, no em dashes, no hedging
stacks. Name uncertainty once, where it applies. Paraphrase sources and link.

## 4. Iterate

Expect the user to steer along these axes, and apply each change across the
whole doc, not only where they pointed:

- **Length and tersity.** Cut by merging and shortening; if later too terse,
  expand the part they name, not everything.
- **Level of detail.** Move implementation debates out; keep decisions the
  reader needs.
- **Skimmability.** Prefer structure (nesting, table rows, bullet counts) over
  prose.
- **Requirement changes.** Update every place a requirement appears: goals,
  requirements, table, delivery phases, open questions, pros and cons.
- **New alternatives or editions.** Add a table column, a section, and any open
  questions together.

The user edits the doc between turns. Re-read it before every edit, preserve
their wording and additions, and mention any of their wording you changed.
After each change, say briefly what changed, what you assumed, and what you
could not verify. Do not claim you checked layout or page count if you did not.

## 5. Verify

Read the doc back and check: section order matches the template, numbering and
counts are consistent, every link is on the right phrase, no stray formatting,
no leftover references to removed content (e.g. a requirement count in an intro
sentence), and the length target is plausible.

## HLD output

Give the user the link to the doc, a short list of what is in it, the main
findings, and the assumptions and unverified items they should check. Keep this
summary shorter than the doc.
