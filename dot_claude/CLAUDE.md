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

# Subagents

Use specialized subagents to handle complex, repetitive tasks more efficiently:

## GitHub Actions Subagent

When working with Pull Requests, use a subagent to monitor GitHub Actions:
* Instead of repeatedly checking and copying GitHub Actions output manually
* Launch a general-purpose subagent to monitor the PR's CI/CD pipeline
* The subagent should use `gh` commands to check workflow runs and report status
* Example tasks:
  - Monitor workflow runs for a specific PR
  - Report failures with relevant error logs
  - Wait for all checks to pass before proceeding

## Lint and Test Subagent

Before committing changes to a branch, use a subagent to run linting and tests:
* Launch a general-purpose subagent to run all relevant linters and tests for the codebase
* The subagent should first inspect `.github/workflows/` to detect what linters and test commands are configured
* Run the same commands that GitHub Actions will run to ensure local checks match CI/CD
* The subagent should report all issues found and only mark complete when all checks pass
* This ensures code quality before creating commits or push requests and prevents CI failures
