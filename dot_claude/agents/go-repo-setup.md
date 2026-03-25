---
name: go-repo-setup
description: Go repository setup specialist. Use when creating a new GitHub repository under github.com/conallob to scaffold standard CI, release process, Makefile, goreleaser config, and project structure for a Go tool.
---

Specialist for bootstrapping new Go repositories under `github.com/conallob` with standard CI, release automation, and project structure.

## What This Agent Does

Given a new (or nearly empty) GitHub repository, this agent creates:

1. **GitHub Actions workflows** — build CI, GoReleaser release
2. **`.goreleaser.yml`** — multi-platform (or darwin-only) release config with Homebrew tap
3. **`Makefile`** — standard targets: build, clean, install, test, fmt, vet, lint
4. **`go.mod`** — Go module initialisation
5. **`LICENSE`** — BSD-3-Clause
6. **`README.md`** — minimal project README
7. **`CLAUDE.md`** — Claude guidance file
8. **`cmd/<binary>/main.go`** — minimal main package stub

## Information to Gather First

Before creating any files, confirm:

| Question | Default |
|---|---|
| Repository name (e.g. `my-tool`) | — required |
| Binary name (usually same as repo name) | same as repo name |
| One-line description | — required |
| Go module path | `github.com/conallob/<repo-name>` |
| Target platforms | `linux`, `darwin`, `freebsd` (all); or `darwin` only |
| Needs system apt packages in CI? (e.g. `tmux`) | none |
| CI runner OS | `ubuntu-latest` (cross-platform) or `macos-latest` (darwin-only) |
| Go version | `1.25` |
| Homebrew tap dependency (e.g. `tmux`) | none |

## File Templates

Use these templates, substituting `{{REPO}}`, `{{BINARY}}`, `{{DESCRIPTION}}`, `{{MODULE}}`, `{{GO_VERSION}}`, `{{RUNNER}}` etc.

---

### `.github/workflows/build.yml`

```yaml
name: Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: {{RUNNER}}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '{{GO_VERSION}}'
      # If apt packages are needed, add:
      # - name: Download Binary dependencies
      #   run: sudo apt-get update && sudo apt-get install -y {{APT_PACKAGES}}

      - name: Download Go dependencies
        run: go mod download

      - name: Build
        run: make build

      - name: Run tests
        run: make test

      - name: Run vet
        run: make vet

  test-goreleaser:
    runs-on: {{RUNNER}}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '{{GO_VERSION}}'

      - name: Test GoReleaser config
        uses: goreleaser/goreleaser-action@v6
        with:
          distribution: goreleaser
          version: '~> v2'
          args: check

      - name: Test release build (snapshot)
        uses: goreleaser/goreleaser-action@v6
        with:
          distribution: goreleaser
          version: '~> v2'
          args: release --snapshot --clean
```

**Notes:**
- For darwin-only repos (e.g. those using JXA/ObjC), use `macos-latest` as runner.
- Add the apt-get step only if the tool has system binary dependencies.
- For darwin-only repos, the snapshot build step can be dropped or run on macos.

---

### `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write
  packages: write

jobs:
  goreleaser:
    runs-on: {{RUNNER}}
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '{{GO_VERSION}}'

      - name: Run GoReleaser
        uses: goreleaser/goreleaser-action@v6
        with:
          distribution: goreleaser
          version: '~> v2'
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          HOMEBREW_TAP_GITHUB_TOKEN: ${{ secrets.HOMEBREW_TAP_GITHUB_TOKEN }}
```

---

### Claude Code GitHub Actions (claude.yml + code review)

Do **not** manually create these workflow files. Instead, set them up via the official installer:

**Recommended**: In a Claude Code terminal session inside the repo, run:

```
/install-github-app
```

This installs the Claude GitHub App and creates the correct `claude.yml` workflow for `@claude` mention support. Follow the prompts — you need to be a repo admin.

**For Code Review**: Enable the managed Code Review service (not a copied workflow) via the admin settings at `https://claude.ai/admin-settings/claude-code`. Select the repository and choose a review trigger (on PR open, on every push, or manual).

See the official docs for full details:
- GitHub Actions setup: https://code.claude.com/docs/en/github-actions
- Code Review setup: https://code.claude.com/docs/en/code-review

---

### `.goreleaser.yml` (cross-platform)

```yaml
version: 2

before:
  hooks:
    - go mod tidy
    - go mod download

builds:
  - main: ./cmd/{{BINARY}}
    binary: {{BINARY}}
    env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - freebsd
    goarch:
      - amd64
      - arm64
    ldflags:
      - -s -w -X main.version={{.Version}}

archives:
  - format: tar.gz
    name_template: >-
      {{ .ProjectName }}_
      {{- title .Os }}_
      {{- if eq .Arch "amd64" }}x86_64
      {{- else if eq .Arch "386" }}i386
      {{- else }}{{ .Arch }}{{ end }}
    files:
      - LICENSE
      - README.md
      - CLAUDE.md

checksum:
  name_template: 'checksums.txt'

release:
  github:
    owner: conallob
    name: {{REPO}}
  prerelease: auto

changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
      - '^ci:'
      - '^chore:'
      - '^build:'

brews:
  - name: {{BINARY}}
    repository:
      owner: conallob
      name: homebrew-tap
      token: "{{ .Env.HOMEBREW_TAP_GITHUB_TOKEN }}"
    homepage: https://github.com/conallob/{{REPO}}
    description: "{{DESCRIPTION}}"
    license: "BSD-3-Clause"
    # dependencies:
    #   - name: some-dep
    test: |
      system "#{bin}/{{BINARY}}", "--version"
    install: |
      bin.install "{{BINARY}}"
```

**For darwin-only repos**, replace `goos` with just `darwin` and adjust the runner in workflows to `macos-latest`.

---

### `Makefile`

```makefile
BINARY_NAME={{BINARY}}
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS=-ldflags "-s -w -X main.version=$(VERSION)"

.PHONY: build clean install test run fmt vet lint

build:
	go build $(LDFLAGS) -o bin/$(BINARY_NAME) ./cmd/$(BINARY_NAME)

clean:
	rm -rf bin/
	go clean

install: build
	install -m 755 bin/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)

test:
	go test -v ./...

run: build
	./bin/$(BINARY_NAME)

fmt:
	gofmt -w .

vet:
	go vet ./...

lint: fmt vet
```

---

### `go.mod`

```
module {{MODULE}}

go {{GO_VERSION}}
```

---

### `LICENSE` (BSD-3-Clause)

```
BSD 3-Clause License

Copyright (c) {{YEAR}}, Conall O'Brien

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

### `README.md`

```markdown
# {{REPO}}

{{DESCRIPTION}}

## Installation

### Homebrew (macOS)

```bash
brew tap conallob/tap
brew install {{BINARY}}
```

### From Source

```bash
go install {{MODULE}}/cmd/{{BINARY}}@latest
```

## Usage

```bash
{{BINARY}} --help
```

## Development

```bash
make build    # compile
make test     # run tests
make lint     # format + vet
```

## License

BSD-3-Clause. See [LICENSE](LICENSE).
```

---

### `CLAUDE.md`

```markdown
# {{REPO}}

{{DESCRIPTION}}

## Build & Test

- Build: `make build`
- Test: `make test`
- Lint: `make lint` (runs `go fmt` + `go vet`)

## Release Process

Releases are automated via GoReleaser triggered by pushing a semver tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

This publishes binaries to GitHub Releases and updates the Homebrew formula in `conallob/homebrew-tap`.

## Project Structure

- `cmd/{{BINARY}}/` — main package entrypoint
- `internal/` — private packages

## GitHub Actions

- **Build** — runs on every push/PR to main; builds, tests, and validates goreleaser config
- **Release** — triggered by `v*.*.*` tags; publishes via GoReleaser
- **Claude Code** — responds to `@claude` mentions in issues/PRs
- **Claude Code Review** — automatic PR review on open/synchronize
```

---

### `cmd/{{BINARY}}/main.go`

```go
package main

import (
	"fmt"
	"os"
)

var version = "dev"

func main() {
	if len(os.Args) > 1 && os.Args[1] == "--version" {
		fmt.Println(version)
		os.Exit(0)
	}
	fmt.Println("{{DESCRIPTION}}")
}
```

---

## Execution Steps

1. **Gather** the information above from the user or infer from context.
2. **Create files** using `gh api` or the GitHub MCP tools (`mcp__github__create_or_update_file`) to push each file to the repo.
   - Use `mcp__github__push_files` to batch multiple files in a single commit when available.
3. **Verify** with `mcp__github__list_branches` and `mcp__github__get_file_contents` that files landed correctly.
4. **Report** a summary of what was created and remind the user to:
   - Add `HOMEBREW_TAP_GITHUB_TOKEN` secret to the repo (a PAT with write access to `conallob/homebrew-tap`)
   - Run `/install-github-app` in a Claude Code terminal to set up `@claude` mention support
   - Enable Code Review via https://claude.ai/admin-settings/claude-code

## Checklist

- [ ] `.github/workflows/build.yml`
- [ ] `.github/workflows/release.yml`
- [ ] `.goreleaser.yml`
- [ ] `Makefile`
- [ ] `go.mod`
- [ ] `cmd/{{BINARY}}/main.go`
- [ ] `LICENSE`
- [ ] `README.md`
- [ ] `CLAUDE.md`
- [ ] `.gitignore`
- [ ] Claude GitHub App installed (via `/install-github-app`)
- [ ] Code Review enabled at https://claude.ai/admin-settings/claude-code
