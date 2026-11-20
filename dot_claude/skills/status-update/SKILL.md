---
name: status-update
description: |
  Compile and format a periodic (usually weekly) status update for a project or effort,
  from the previous update, the issue tracker and GitHub, and save it as a Slack draft
  for the user to review and send. Never sends. Works interactively or unattended in a
  scheduled session with nobody to escalate to.
  Use when: the user asks for a status update, weekly update, project update or
  "what landed this week" write-up, or a scheduled task invokes it with project inputs.
  Takes the project specifics (channel, tracker query, umbrella issues, repos, audience)
  as inputs, so the same skill serves any project.
user-invocable: true
---

# /status-update: Project Status Update

Draft a status update for one project or effort, in the same shape as the previous
update, and save it as a **Slack draft**. The user reviews and sends it themselves.

**Never send the message. Never post anywhere else. Never edit the tracker or GitHub.**
This skill is read-only apart from saving one draft.

## Inputs

The caller supplies these in the prompt or arguments. Anything missing falls back as
described in "Interactive vs scheduled".

| Input | Meaning | Example |
|-------|---------|---------|
| `project` | Display name | Project Phoenix |
| `author` | Whose voice; whose update it is; GitHub handle | Jane Doe, `janedoe` |
| `channel` | Slack channel name and id to read and to save the draft in | #project-phoenix, C0123456789 |
| `post_marker` | First line of the author's previous updates, used to find them | `Weekly Status Update:` |
| `tracker_query` | Which tracker issues are in scope: label/team and umbrella issues whose children count | Linear label `phoenix`, team Platform, umbrellas PLT-100 and PLT-200 |
| `repos` | GitHub repos to check for PRs (read-only; never clone) | acme/service-a, acme/service-b |
| `audience` | Who reads it and what that means for tone | Partly non-technical stakeholders |
| `standing_sections` | Sections that must appear every time, and the message they carry | Keep Blocked every week: most remaining work is waiting on other teams |
| `counts` | Project-specific tallies to compute and how to count them | New alert rules in PRs under umbrella PLT-200 |
| `people` | Names with resolved Slack user ids for mentions | Alex `<@U0000000001>` |

## Interactive vs scheduled

Decide which mode applies before starting.

- **Interactive** (a person is in the session): ask once, up front and together, for any
  required input you cannot find (`channel`, `tracker_query`, `repos`). Offer your best
  guess for each so they can just confirm. Do not ask about things you can resolve by
  reading the channel or tracker.
- **Scheduled / unattended** (the prompt says so, or there is no way to get an answer):
  never ask a question and never wait. Proceed with what you have. Every place you would
  have asked becomes a `[CHECK: ...]` marker in the draft and a line in the final reply.
  If a required input is genuinely absent (no channel, no tracker scope), stop and say
  exactly what was missing in the final reply rather than guessing.

In both modes the rules below are identical. Interactive mode just lets the person
resolve `[CHECK]` items before the draft is saved, if they are there to do it.

## Steps

### 1. Read the channel

- Find the author's most recent posts that start with `post_marker` (last 2-3).
- Read the replies in the latest post's thread.
- **Use the latest post as the template**: section names, order, tone and length.
- Record its date. **"This week" means since that date**, not the last 7 days.
- Note any recurring bot posts in the channel (for example a Friday table of open PRs
  with days waiting and review state). You will use these for Out for Review.
- If there is no previous post, use the section list in step 5 and add
  `[CHECK: no previous update found, using default template]`.

### 2. Read the tracker

- List issues in `tracker_query` scope, including children of any umbrella issues.
  Fetch state, completedAt and updatedAt.
- Read the full issue (not just the list row) for anything Blocked or ambiguous.
- Tracker output is often large. Save it to a file in the scratchpad and parse it with a
  script rather than reading it raw into context.

### 3. Read GitHub

- For each repo in `repos`: open and recently merged PRs by `author`, with review state.
- **A PR closed without merging is abandoned.** Do not list it under Landed or Out for
  Review. A tracker issue closed to tidy up after an abandoned PR is housekeeping, not a
  landing.
- If a repo is not in scope for your GitHub tools, attach it with `add_repo` (read-only).
  Never clone.

### 4. Compute `counts`

Follow the counting rule the caller gave. Read the PR description or issue body, not
just the title. Count only genuinely new items; do not count renames, severity changes
or value tweaks. Split into "landed since last post" vs "still in review". State any
caveat the sources give (for example: alerts in a testing target only, or silent until
a dependency exists).

### 5. Write the update

Sections, in this order. Omit a section only where noted.

1. First line: the `post_marker` text, exactly.
2. `TL; DR:` (keep that spelling). 3-5 plain-language bullets: what is built, what is
   waiting on others, any data caveat. No jargon, no ticket IDs.
3. `Landed:` only what finished **since the last post**: tracker Done after its date, or
   PR merged since. Never repeat earlier Landed items.
4. `In Progress:` active work and anything landed in part, plus any `counts` callout.
5. `Next Week:` **one bullet per tracker issue, never combined**, each with its URL. Base
   it on In Progress or Todo issues that are unblocked.
6. `Currently Blocked:` one bullet per blocker, with the URL and **what it is blocked on**
   (a decision, a dataset, a join, a legal answer, a named person). Carry forward blockers
   still open; drop ones that cleared.
7. `Out for Review:` only if open PRs remain. PR link and days waiting from the bot
   table. Do not claim reviewers or CI state you did not check.

Honour `standing_sections`: if the caller says a section must appear every week, include
it even when empty, with a brief "nothing new this week" line.

If nothing changed in a section, say so briefly instead of padding it.

Write for `audience`. If any reader is non-technical, explain outcomes before mechanisms.

### 6. Do not invent

- If a status is ambiguous (ticket closed but PR still open; ticket In Review but you are
  calling it landed; a blocker visible in chat but not recorded in the tracker), **keep the
  item and add `[CHECK: <what is unclear>]`** on the same bullet.
- Never fill a gap with a plausible guess. A visible `[CHECK]` is cheaper than a wrong claim
  going to stakeholders.
- Mention people as Slack mentions only for ids in `people`; otherwise plain names. Never
  guess a user id.

### 7. Save the draft

Save with the Slack draft tool, in `channel`. Slack allows **one draft per channel**.

- If the tool returns `draft_already_exists`: **do not overwrite it, delete it, or work
  around it** (no posting elsewhere, no alternative channel, no DM). Put the full draft
  text in the final reply and say a draft already exists.
- If the draft tool is unavailable or fails for any other reason: same fallback. Give the
  full text and the reason. Do not substitute another channel or tool that would publish it.
- If you cannot confirm the draft was saved, say so. Do not claim it was.

## Slack formatting

The text is pasted by the author into Slack, so use plain text that survives that.

- Top-level bullets start with `*`. The `•` character does not survive pasting.
- Slack cannot nest bullets in plain text: avoid sub-bullets. Put extra detail in the
  same sentence. Use an indented `◦` line only for a `counts` callout or a short
  rationale note the previous posts already used it for.
- Links are **bare, full URLs** (never truncate a slug), placed after a colon at the end
  of the bullet. No Markdown links, and no punctuation after a URL.
- One sentence per bullet.
- Straight quotes only.
- One blank line between sections; never two in a row.
- Section headers are the plain text lines named above, no Markdown headings or bold unless
  the previous post used them.

Before saving, re-read the text once against this list and against the "never combine
issues" and "no repeated Landed items" rules.

## Final reply

Always give:

1. The full draft text.
2. The link to the saved draft, or the reason it could not be saved.
3. A short list of every `[CHECK]` item (also left inline in the draft).

In scheduled mode, make the reply self-contained: it may be the only thing anyone reads.
Do not post anywhere else, do not edit the tracker or GitHub, and do not send the message.
