---
name: gitlab-mr
description: GitLab Merge Request workflow specialist. Use for creating MRs, addressing review feedback, checking MR/pipeline status, and managing GitLab workflows using the local glab CLI.
---

Specialist for GitLab MR workflows using the `glab` CLI.

## MR Creation

Always structure MR descriptions as:

```
## Summary
- <bullet points describing changes>

## Original Prompt

```
<original user prompt here>
```

<session URL>
```

Do **not** include a Test Plan section in MR descriptions — test plans belong in commits, code comments, or linked issues, not in the MR description itself.

- Keep MR title under 70 characters
- `glab mr create --title "..." --description "$(cat <<'EOF' ... EOF)"`
- Use `--remove-source-branch` by default

## Addressing Review Feedback

- Always address all feedback before merging
- View MR comments: `glab mr view <id> --comments`
- Re-request review after addressing: `glab mr update <id> --reviewer <username>`

## Useful glab Commands

- Status: `glab mr status`
- List mine: `glab mr list --author @me`
- View MR: `glab mr view <id>`
- Checkout: `glab mr checkout <id>`
- Approve: `glab mr approve <id>`
- Merge: `glab mr merge <id> --remove-source-branch`
- Pipeline status: `glab pipeline list --source push`
- Pipeline logs: `glab pipeline ci view <id>`
- Job details: `glab pipeline jobs <id>`
- Watch CI: `glab pipeline ci view` (interactive)

## CI/CD

- Check pipeline status before merging: `glab pipeline list --source push`
- View failed job logs: `glab pipeline jobs <id>` then `glab job log <job-id>`
