---
name: project-postmortem
description: |
  Draft a blameless postmortem (retro, project review, lessons-learned
  write-up) for a finished or stalled project, where every claim traces to a
  source and the draft is ready for a team to review without anyone feeling
  blamed.
  Use when: the user asks for a postmortem, retro, project review or
  lessons-learned write-up for a project (not a production incident), or names
  sources to mine (chat history, meeting notes, tickets, pull requests) or
  contributing factors to cover.
  Do not use for a live incident timeline, a production-incident postmortem or
  a status report.
user-invocable: true
---

# /project-postmortem — Draft a blameless project postmortem

Produce a draft for human review, not a final record. The reader should be
able to check any claim against its source, and nobody named in it should feel
blamed. Section layout, factor prompts and examples are in `references/`; a
blank outline is `references/template.md`.

## Workflow

1. **Outline first.** Create the document from `references/template.md`
   before researching, so reviewers can watch it fill. Use the team's
   editable document system if one is connected.
2. **Gather evidence**, in this order, using whatever the team has connected
   (chat, meeting notes, ticket tracker, code host):
   1. Project channel history in full, including thread replies. Status
      updates are the best spine for the timeline.
   2. Meeting notes and transcripts for decisions, feedback sessions and
      retros. Search summaries first; read transcripts only for exact details.
   3. Tickets, by label and by umbrella ticket. Count them by state and list
      the blocked ones with the reason.
   4. Pull requests referenced from tickets or status updates. Record review
      wait times and merge states.
   5. Direct messages, only if the user asks. Use them for dates and project
      facts. Leave out personal, interpersonal and hiring content, and say so
      in the sources section.

   If a source cannot be reached, say so in the document and mark everything
   that depends on it as unverified.
3. **Ask the user for contributing factors**, then test each against the
   record. `references/structure-and-factors.md` lists common categories to
   prompt with. A factor the record does not support is either cut or kept
   as the user's account, marked `[confirm]`.
4. **Fill the sections.** Lead each with its point. Write the summary last so
   its numbers match the body.
5. **Run the verification pass** below, then hand over.

## Writing rules

- **Blameless.** Describe conditions, decisions and missing mechanisms, not
  individuals. Where two people held different views, state both as
  reasonable and name the missing piece (for example, no agreed priority
  order).
- **Evidence for every factor.** Each needs at least one dated, sourced fact.
  If the only source is the user's own account, keep it and mark it
  `[confirm]`.
- **Calibrated claims.** Do not turn a correlation into a cause. Write
  "consistent with" when the record only suggests it. Remove a claim the
  sources do not support rather than softening it.
- **Verify numbers.** Recount ticket states from the data, check day counts
  against the dates, and do not mix up a ticket's filing date and completion
  date.
- **Mark gaps** with `[confirm]` inline, and collect every one in the
  open-items checklist.
- **Owners are proposals.** Label them as such, and state a target date only
  if one appears in the record. Do not invent owners.
- **Plain, direct prose.** Tables for timelines, gaps and action items;
  bullets only for parallel items.
- **Respect quote limits.** Paraphrase source text; never paste long passages
  from messages or meeting notes.

Each contributing factor and action item follows the worked examples in
`references/examples.md`. Action items address a named factor or gap, and
prefer practices (a kickoff checklist, code-ownership files, a freshness
alert on every data feed) over one-off fixes.

## Verification pass before handoff

1. Every number in the summary matches the body.
2. Every ticket and PR reference exists and is described correctly.
3. No sentence blames a person or guesses at motives.
4. Every `[confirm]` marker appears in the open-items checklist.
5. The sources section states what could not be read.

## Delivery

Create the draft as an editable document so reviewers can comment inline.
Tell the user in one or two sentences what it contains and what needs
confirming. Export to the team's document system only when the user says the
draft is ready for wider review.
