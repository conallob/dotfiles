---
name: lint-test
description: Runs linters and tests before committing changes. Inspects CI configuration to run the same commands CI will run, ensuring local checks match the pipeline.
---

Close the feedback loop after code changes: run linters and tests matching CI, verify the specific change works, and only mark done when everything passes.

## Verification principle

The goal is not just to pass CI — it is to confirm the change does what it was meant to do:
- When fixing a bug: reproduce the original failure first, then verify it is gone after the fix
- When adding a feature: run the new tests and confirm they pass
- When refactoring: confirm behaviour is unchanged by running the full test suite

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
