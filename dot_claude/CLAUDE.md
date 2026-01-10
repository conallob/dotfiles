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

# Subagents

Use specialized subagents to handle complex, repetitive tasks more efficiently:

## CI/CD Monitoring Subagent

When working with GitHub Pull Requests or GitLab Merge Requests, use a subagent to monitor CI/CD pipelines:
* Instead of repeatedly checking and copying CI/CD output manually
* Launch a general-purpose subagent to monitor the PR/MR's CI/CD pipeline
* For GitHub: The subagent should use `gh` commands to check workflow runs and report status
* For GitLab: The subagent should use `glab` commands to check pipeline runs and report status
* Example tasks:
  - Monitor workflow/pipeline runs for a specific PR/MR
  - Report failures with relevant error logs
  - Wait for all checks to pass before proceeding

## Lint and Test Subagent

Before committing changes to a branch, use a subagent to run linting and tests:
* Launch a general-purpose subagent to run all relevant linters and tests for the codebase
* The subagent should first inspect CI configuration to detect what linters and test commands are configured:
  - For GitHub: Check `.github/workflows/` for GitHub Actions workflows
  - For GitLab: Check `.gitlab-ci.yml` and any yaml files under `.gitlab/` for GitLab CI configuration
* Run the same commands that the CI/CD platform will run to ensure local checks match CI/CD
* The subagent should report all issues found and only mark complete when all checks pass
* This ensures code quality before creating commits or push requests and prevents CI failures

## Spell Check Subagent

Before committing changes, use a subagent to check spelling in code, documentation, and comments:
* Launch a general-purpose subagent to run spell checking on modified files
* The subagent should check:
  - Documentation files (*.md, *.rst, *.txt)
  - Code comments and docstrings
  - Commit messages
  - String literals where appropriate (excluding technical terms, variables, APIs)
* Use tools like `codespell`, `aspell`, or `typos` if available in the project
* Report spelling errors with suggestions for corrections
* The subagent should only mark complete when all spelling issues are addressed or intentionally ignored
* This prevents typos from making it into commits and improves documentation quality
