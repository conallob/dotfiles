# Common Claude Instructions Across all Sessions
# Per https://www.anthropic.com/engineering/claude-code-best-practices#1-customize-your-setup

# Code Style
* Use standard libraries as much as possible
* Avoid single letter variable names, except for trivial loop variables
* Strive for clean, self documenting code
* Leave annotations for humans to understand

# Testing
* Always write unittests when writing languages such as Go or Python
* Always run linters, `golangci-lint` and `go fmt` for Golang , `black`, `ruff` for Python
* Always run Python operations (linting, testing, package installs) inside a virtualenv managed via `mkvirtualenv` (virtualenvwrapper); never use system Python

# Workflow
* When working on Github repositories under github.com/conallob , always install Claude App and Claude Github Actions
* When working on GitHub Pull Requests or GitLab Merge Requests, always address all PR/MR feedback provided by Claude Code Review
* When creating Pull Requests or Merge Requests, include the primary prompts as multiline markdown code blocks in the PR/MR description
  - This provides context for reviewers about the original intent and scope
  - Format prompts using markdown code fences (triple backticks)
  - Example format in PR/MR description:
    ```
    ## Original Prompt

    ```
    Create a new branch to update @dot_claude/CLAUDE.md to use subagents...
    ```
    ```

# Agents

Specialised agents are defined in `~/.claude/agents/`. Use them for:
* `cicd-monitor` — monitor GitHub/GitLab CI pipelines for a PR/MR
* `lint-test` — run linters and tests matching CI configuration before committing
* `spell-check` — check spelling in modified files before committing
* `go-dev` — Go formatting, linting, testing, and module management
* `python-dev` — Python formatting, linting, type checking, and testing
* `chezmoi` — dotfiles template editing, validation, and apply workflow
* `github-pr` — GitHub PR creation, review response, and gh CLI workflows
* `k8s` — Kubernetes, kustomize, and Talos cluster operations
* `obsidian` — capture notes and search the Obsidian vault
* `omnifocus` — capture tasks and TODOs into OmniFocus
* `home-assistant` — HA config repo, automation/script authoring, config reload, MCP queries
* `incident-response` — incident triage, log analysis, and incident.io coordination (work only)
