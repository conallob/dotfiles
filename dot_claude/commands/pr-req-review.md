---
description: Print a Slack-pasteable list of my open PRs awaiting review, grouped by umbrella effort
argument-hint: "[--repo owner/name] [--author login] [--branch-prefix prefix] [--exclude 123,substring] [--status]"
---

Produce a list of my open pull requests that I can paste into Slack to ask for review.
This command only prints text. Never post to Slack and never comment on, approve, or edit
any PR.

## Arguments

Parse `$ARGUMENTS` (all optional):

- `--repo owner/name`: repo(s) to search, comma-separated. Default: `andromeda-ai/platform`.
- `--author login`: PR author. Default: `conallob`.
- `--branch-prefix prefix`: only PRs whose head branch starts with this prefix, e.g.
  `conall_claude/` for my agent branches (they look like `conall_claude/<ticket>-<slug>`).
- `--exclude a,b,c`: PR numbers or title/branch substrings to leave out. There are no
  default exclusions: only exclude what is passed here.
- `--status`: append a terse blocker note to a PR (see Status below). Off by default.

## Find the PRs

- Open means not draft, not merged, not closed.
- Use the GitHub MCP tools (`mcp__github__list_pull_requests`, `mcp__github__pull_request_read`).
  Load them with ToolSearch if their schemas are not available. `gh` is fine if it exists
  locally. If the MCP `search_*` tools are unavailable, use
  `gh api -X GET search/issues -f q='repo:<repo> is:pr is:open draft:false author:<author>'`.
- Filter by author, draft state and branch prefix yourself if the listing tool cannot.
- If a repo is not accessible, say so in the summary line and carry on with the rest.

## Group by umbrella effort

- Each top-level bullet is an umbrella effort: a Linear parent issue or a theme. PRs are
  sub-bullets underneath it.
- Take the ticket id (e.g. `SE-1847`) from the branch name or the PR title. When the Linear
  tools are available, look up that ticket's parent and name the umbrella after it
  (e.g. `SE-1830: v1-to-v2 alerting/monitoring parity`).
- If Linear is not reachable, group by PR title prefix or shared ticket id and say so in the
  summary line.
- PRs that fit no umbrella go under `Other`.

## Format

- One sub-bullet per PR: a one-line plain-English description, then the full URL:
  `- Export node hardware/firmware versions from the node agent: https://github.com/andromeda-ai/platform/pull/8282`
- Always the full `https://github.com/<owner>/<repo>/pull/<n>` URL so Slack unfurls it.
  Never write a bare `#123` or `PR #123`.
- Plain text that survives a Slack paste: simple `-` bullets and indentation. No tables,
  no HTML, no markdown headings.
- Write the description from the PR diff, title and body, not only the title: say what
  changes and, when it matters, the blast radius. Keep it to one line.

## Status (only with `--status`)

Append a short note after the URL only when something blocks review, e.g.
`needs fresh approval on latest head` or `CI red on main-wide failures`. The repo requires an
approval on the current head commit from someone other than the author, and new commits or
force-pushes dismiss approvals, so a PR "awaiting review" may only need a fresh approval
after a push. Check approvals against the head SHA and the check runs. Omit the note for
PRs with nothing blocking.

## Output

Print one line, then the list in a single fenced code block so it copies cleanly. The line
says how many PRs were included, which were excluded (by number), and any fallback used
(e.g. Linear unavailable). Print nothing else. If no PRs match, say so in that one line.
