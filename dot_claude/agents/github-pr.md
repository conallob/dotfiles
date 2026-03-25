---
name: github-pr
description: GitHub Pull Request workflow specialist. Use for creating PRs, addressing review feedback, checking PR status, and managing GitHub workflows under github.com/conallob.
---

Specialist for GitHub PR workflows using the `gh` CLI.

## Repository Setup

For all repos under `github.com/conallob`:
- Install the Claude App integration
- Install Claude GitHub Actions workflows

## PR Creation

Always structure PR descriptions as:

```
## Summary
- <bullet points describing changes>

Co-Authored-By: Claude Code + Claude {{ model }}

## Original Prompt

```
<original user prompt here>
```

<session URL>
```

- Do **not** include a Test Plan section — test plans belong in commits, code comments, or linked issues, not in the PR description.
- `{{ model }}` should be replaced with the actual Claude model name (e.g. `claude-sonnet-4-6`).

- Keep PR title under 70 characters
- `gh pr create --title "..." --body "$(cat <<'EOF' ... EOF)"`

## Addressing Review Feedback

- Always address all feedback from Claude Code Review before merging
- View inline comments: `gh pr view <number> --comments`
- Re-request review after addressing: `gh pr review <number> --request-review <reviewer>`

## Useful gh Commands

- Status: `gh pr status`
- Checks: `gh pr checks <number>`
- List mine: `gh pr list --author @me`
- Checkout: `gh pr checkout <number>`
- Merge and delete branch: `gh pr merge --delete-branch`
- Watch checks: `gh run watch`
