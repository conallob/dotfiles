---
name: talking-points-template
description: |
  Turn a Claude sounding-board conversation about an upcoming meeting into a printable
  talking points template for taking handwritten notes on a reMarkable 2 tablet.
  Use when: the user has just finished thinking out loud about a meeting (prep, 1:1,
  interview, negotiation, incident review, etc.) and wants a notes template to bring
  into it. Covers: extracting talking points/questions/decisions from the conversation,
  formatting for reMarkable 2's portrait e-ink screen, leaving generous handwriting
  space, and structuring the doc so notes taken during the meeting are easy to move
  into Obsidian afterwards.
user-invocable: true
---

# /talking-points-template — Meeting Notes Template for reMarkable 2

Generate a talking points template from the meeting prep discussion in this
conversation, formatted for handwritten note-taking on a reMarkable 2 tablet,
and structured so the notes taken during the meeting are easy to retrieve
into Obsidian afterwards.

## When to use this

The user has been using the conversation as a sounding board to prepare for a
meeting — thinking out loud, working through what they want to say or ask.
Once their talking points are settled, this skill turns that into a template
document they export/print to their reMarkable 2 and write on during the
meeting itself.

## Step 1 — Extract the talking points

Review the conversation so far and pull out:
- **Meeting context**: who it's with, what kind of meeting (1:1, negotiation,
  interview, incident review, status update, etc.), and when, if known
- **Objective**: what the user wants to walk away with
- **Talking points**: the key things the user decided they want to say or cover,
  in the order they're likely to come up
- **Open questions**: things the user wants to ask or get clarity on
- **Risks / pushback to anticipate**: objections or difficult moments the user
  flagged while thinking it through
- **Decisions needed**: anything that needs a decision or commitment by the end

Don't invent talking points that weren't discussed — if the conversation was
thin on a section, leave it short rather than padding it out.

## Step 2 — Format for reMarkable 2

The reMarkable 2 has a **1404×1872 portrait e-ink display** (no color, no
backlight) and is used with the stylus for handwriting, so the template must
optimize for handwriting space, not information density:

- **Portrait orientation**, single column
- Print each talking point as a **short heading or bullet**, then leave a
  **generous blank writing area** below it (several blank lines' worth, or a
  clearly bounded box) — the user will fill this in by hand during the meeting
- Avoid dense paragraphs, tables, or small text — e-ink and handwriting both
  need room to breathe
- Keep total talking points to what fits on one or two pages; don't cram
  because it's a template, not a transcript
- No color-dependent formatting — the display is grayscale
- Prefer numbered or clearly separated sections so pages can be flipped
  through quickly mid-meeting

Default output format is a **Markdown file** (works well with the
reMarkable's Markdown/PDF conversion, or via the reMarkable "Read on
reMarkable" / send-to-device flow). If the user has a PDF-generation
workflow already set up, offer to produce a PDF instead — otherwise Markdown
is the default and simplest to hand off.

### Template skeleton

```markdown
# <Meeting title> — <date>

**With:** <attendees>
**Objective:** <one line>

---

## 1. <Talking point>




## 2. <Talking point>




## Questions to ask

- <question>


- <question>


## Anticipated pushback

- <concern> → <response>


## Decisions needed

-


## Follow-ups (fill in during/after)

-
```

Adjust section count and blank space to match what the conversation actually
produced — don't force every section if it doesn't apply (e.g. skip
"Anticipated pushback" for a routine status update).

## Step 3 — Set up for Obsidian retrieval

The user's meeting notes end up in Obsidian afterwards, so make the template
easy to file there without reformatting:

- Add YAML frontmatter matching the vault's convention (see the `obsidian`
  agent for format): `tags`, `date`, and a `meeting` tag/type so it's
  filterable later
- Name the file so it sorts and searches well, e.g.
  `YYYY-MM-DD-<short-meeting-slug>.md`
- Keep headings as real Markdown headings (`##`, not bold text standing in
  for headings) so Obsidian's outline/search still works once it's imported
- Mention to the user that once notes are handwritten and synced off the
  reMarkable (via OCR export or manual transcription), the same file can be
  updated in place or pasted into the vault under the existing note

Example frontmatter:
```markdown
---
tags: [meeting, <topic>]
date: <YYYY-MM-DD>
meeting: <short type, e.g. 1:1, negotiation, review>
---
```

## Step 4 — Deliver

- Write the file to the user's working directory (or scratchpad if this is a
  one-off) as `<date>-<meeting-slug>.md`
- Show the rendered content back to the user for a quick sanity check before
  they export it to the tablet
- If asked, offer to also save a copy straight into the Obsidian vault via
  the `obsidian` agent, rather than leaving it as a loose file
