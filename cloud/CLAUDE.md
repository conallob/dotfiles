# Common Claude Instructions Across all Sessions
# Cloud copy of dot_claude/CLAUDE.md.tmpl, minus what only exists on my own machines
# (local agents, commands, MCP servers). Keep the two in step.

# Code Style
* Use standard libraries as much as possible
* Avoid single letter variable names, except for trivial loop variables
* Strive for clean, self documenting code
* Leave annotations for humans to understand
* Write the minimum code that solves the problem — nothing speculative or anticipatory
* Touch only what the task requires; clean up only your own mess, not surrounding code

# Testing
* Always write unittests when writing languages such as Go or Python
* Always run linters, `golangci-lint` and `go fmt` for Golang , `black`, `ruff` for Python
* Always run Python operations (linting, testing, package installs) inside a virtualenv; never use system Python

# Verification
* Define success criteria before starting — know what "done" looks like before writing any code
* Always close the feedback loop after code changes — run the linters and tests before considering a task done
* When fixing a bug: reproduce the failure first, then verify it is gone
* Review non-trivial code changes for quality, reuse, and efficiency
* Don't assume. Don't hide confusion. Surface tradeoffs and ambiguity explicitly before proceeding

# Workflow
* When working on Github repositories under github.com/conallob , always install Claude App and Claude Github Actions
* When working on GitHub Pull Requests or GitLab Merge Requests, always address all PR/MR feedback provided by Claude Code Review
* All GitHub Pull Requests and GitLab Merge Requests must:
  - Be scoped to just the immediate issue in scope
  - Have side quests approved before proceeding
  - Have a description that always matches the diff
  - Have a terse description that is to the point, with no additional context unless instructed

# Git Usage
* When performing git operations, all commits must be signed with my SSH signing key (the one in git's `user.signingkey`), not any other SSH key
* When working in a git repository, if the most recently opened PR/MR for the current branch has already been merged and further instructions are given, always create a new branch before making further changes — never stack new commits onto a branch whose PR has already merged
  - Base the new branch on the latest default branch (e.g. `main`)
