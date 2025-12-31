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

# Workflow
* When working on Github repositories under github.com/conallob , always install Claude App and Claude Github Actions
* When working on Github Pull Requests, always address all PR feedback provided by Claude Code Review
