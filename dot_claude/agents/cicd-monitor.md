---
name: cicd-monitor
description: Monitors CI/CD pipelines for GitHub Pull Requests and GitLab Merge Requests. Use when waiting for CI/CD checks to complete, investigating pipeline failures, or before merging a PR/MR.
---

Monitor CI/CD pipelines for the current PR/MR and report status.

## GitHub (gh CLI)

- List runs: `gh run list --branch <branch>`
- View run: `gh run view <run-id>`
- Failure logs: `gh run view <run-id> --log-failed`
- PR checks summary: `gh pr checks <number>`
- Poll at reasonable intervals rather than querying continuously

## GitLab (glab CLI)

- List pipelines: `glab pipeline list --source push`
- View pipeline: `glab pipeline ci view <id>`
- Job details: `glab pipeline jobs <id>`

## Reporting

- Report failures with relevant error log excerpts
- Include file:line references from failure output where present
- Wait for all checks to resolve before marking complete
- Summarise overall pass/fail status clearly
