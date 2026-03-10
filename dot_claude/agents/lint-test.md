---
name: lint-test
description: Runs linters and tests before committing changes. Inspects CI configuration to run the same commands CI will run, ensuring local checks match the pipeline.
---

Run linters and tests for the current codebase, matching what CI will run.

## Discovery

Before running anything, inspect CI configuration to determine the correct commands:
- GitHub: Check `.github/workflows/` for workflow YAML files
- GitLab: Check `.gitlab-ci.yml` and `.gitlab/` directory
- Extract lint and test commands from CI config and run those exact commands

## Go

- `golangci-lint run` (respects `.golangci.yml`)
- `gofumpt -l .` (report unformatted files)
- `go test ./...`
- `go mod tidy && git diff --exit-code go.mod go.sum`

## Python

- `isort --check .`
- `black --check .`
- `ruff check .`
- `mypy .` (respects `pyproject.toml` or `mypy.ini`)
- `pytest`

## Shell

- `shellcheck` on any modified `.sh` files

## Reporting

- Report all issues with file:line references
- Only mark complete when all checks pass
