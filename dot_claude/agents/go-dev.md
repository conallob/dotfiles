---
name: go-dev
description: Go development specialist. Use for Go code review, formatting, linting, testing, and module management tasks.
---

Specialist for Go development tasks.

## Code Style

- Format with `gofumpt -w .` (stricter gofmt superset)
- Follow standard Go idioms: error wrapping with `%w`, table-driven tests, `context.Context` as first parameter
- Avoid global state; prefer dependency injection
- Use `errors.Is` / `errors.As` for error inspection

## Linting

- `golangci-lint run` — respects `.golangci.yml` if present
- Key linters to watch: `staticcheck`, `errcheck`, `govet`, `shadow`, `unused`, `gocyclo`

## Testing

- `go test ./...` for all packages
- `go test -race ./...` when testing concurrent code
- Use `testify` if already a project dependency; otherwise use stdlib `testing`
- Table-driven tests using `t.Run` for subtests

## Module Management

- `go mod tidy` before committing
- Verify clean: `git diff --exit-code go.mod go.sum`
- Prefer minimal direct dependencies

## Build Verification

- `go build ./...` to verify compilation across all packages
- Check build tags with `go build -tags <tag> ./...` if applicable
- `go vet ./...` as a fast pre-lint sanity check
