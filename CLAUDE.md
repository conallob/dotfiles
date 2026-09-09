# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **chezmoi-managed dotfiles repository** for managing personal configuration across macOS,
FreeBSD, and Linux systems. The repository uses chezmoi's templating system with 1Password integration for secrets management.

## Git Workflow

**This repository typically works directly on the `main` branch.**

**For all PRs, always ensure the description matches the diff**

Since this is a personal dotfiles repository managing system configurations,
changes are usually committed directly to main. Feature branches should be
**infrequent** and only used for:
- Major refactoring or architectural changes
- Experimental configurations that need testing before deployment
- Changes that require review or collaboration

For routine configuration updates (adding packages, updating settings,
fixing bugs), commit directly to main.

**Don't include Test Plan details within a PR description**

## Key Architecture Patterns

### Chezmoi Naming Convention

Files and directories use chezmoi's special prefix naming:
- `dot_*` → becomes `.` in the home directory (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_*` → file permissions set to private (0600 or 0700)
- Combined: `private_Application Support/private_Claude` → `~/.config/Application Support/Claude/` with appropriate permissions

### Template System

Files with `.tmpl` extension are processed by chezmoi using Go templates:
- **1Password Integration**: Uses `onepasswordDetailsFields` and `onepasswordDocument` functions to inject secrets
- **Conditional Logic**: `{{- if eq (includeTemplate "isWorkAccount" .) "true" }}` gates work-specific configurations. `isWorkAccount` is a shared template partial (`.chezmoitemplates/isWorkAccount`) computed by checking whether the hostname starts with `andromeda` (case-insensitive), rather than checking username
- **JSON Template Files**: Files ending in `.json.tmpl` use Go `text/template` syntax:
  - Use `{{/* comment */}}` for template comments (not JSON comments)
  - Be mindful of trailing whitespace in the rendered output - use `{{-` and `-}}` to trim whitespace
  - Test rendered output with `chezmoi execute-template` to verify proper JSON formatting

### Chezmoi Template Data Gotchas

- **`.chezmoidata.<format>` does NOT support a `.tmpl` suffix.** Only `.chezmoiexternal.<format>` files can be templated (`.chezmoiexternal.toml.tmpl`); a file named `.chezmoidata.toml.tmpl` is not recognized as a data file at all — chezmoi treats it as an ordinary template and would apply it as a literal dotfile target. For computed/dynamic values (e.g. anything derived from `.chezmoi.hostname`), use a **`.chezmoitemplates/<name>` partial** instead and pull its value with `includeTemplate "<name>" .` (returns a string — compare with `eq ... "true"` for booleans). `.chezmoitemplates/` entries are excluded from being applied as targets and are always re-evaluated as templates.
- **`dot_config/chezmoi/chezmoi.toml.tmpl` only renders on `chezmoi init`.** It is never retemplated by `chezmoi apply` or `chezmoi update` — an existing install's `~/.config/chezmoi/chezmoi.toml` won't pick up new template logic added there until re-init. Don't rely on it for values other templates need on every run; use a `.chezmoitemplates/` partial (or compute inline) instead.
- **`chezmoi execute-template < file` (used in CI) evaluates only that one file** — it does not implicitly load other source-tree data unless the mechanism used to expose that data (like `.chezmoitemplates/`) resolves it per-invocation via a template function such as `includeTemplate`. When adding a new templating mechanism, verify it works under `chezmoi execute-template` directly (as CI runs it) and not just under `chezmoi apply`/`update`.

### Multi-Platform Configuration Strategy

The repository uses a cascading configuration pattern for platform and host-specific settings:

1. **Base configuration**: `shell.d/env` and `shell.d/alias`
2. **Platform-specific**: `shell.d/env.Darwin`, `shell.d/alias.Darwin` (also FreeBSD, Linux)
3. **Host-specific**: `shell.d/env.$(hostname -s)`, `shell.d/alias.$(hostname -s)`

This is sourced hierarchically from `dot_zshrc`, which:
- Sets up PATH with support for Homebrew (`/opt/homebrew/`), MacPorts (`/opt/local/`), and domain-specific installs
- Initializes atuin for shell history
- Loads platform-specific `dot_zsh/zshrc.$(uname -s)`
- Sources the cascading shell.d configs

## Working with This Repository

### Applying Changes

```bash
# Preview what would change
chezmoi diff

# Apply all changes
chezmoi apply

# Apply specific file
chezmoi apply ~/.zshrc

# Edit and apply in one step
chezmoi edit --apply ~/.zshrc
```

### Working with Templates

When editing template files:
1. Edit the source: `chezmoi edit <file>`
2. Templates are in the chezmoi source directory (find with `chezmoi source-path`)
3. Test with: `chezmoi execute-template < template-file`

### Managing Secrets

Secrets are stored in 1Password and templated at apply-time:
- **API keys/tokens**: `onepasswordDetailsFields` for structured fields
- **Documents**: `onepasswordDocument` for full credential documents
- Never commit raw secrets; always use 1Password template functions

#### onepasswordDetailsFields usage

```
{{ (onepasswordDetailsFields "ITEM-UUID").FIELD.value }}
```

The function signature is `(item-uuid [vault-uuid [account-uuid]])`. The item UUID
alone is sufficient — vault and account qualifiers are optional and can cause
"no 1Password account found" errors if the wrong UUID is placed in the wrong
position. Find the item UUID from the 1Password URL parameter `i=`.

The field name matches the label shown by `op item get ITEM-UUID` (e.g.
`credential`, `password`, `username`). Use `op item get ITEM-UUID --reveal`
to confirm field names without exposing values in this file.

### Claude Desktop MCP Configuration

The main MCP configuration is at `Library/private_Application Support/private_Claude/claude_desktop_config.json.tmpl`:
- Contains multiple MCP servers (Obsidian, OmniFocus, Home Assistant, JetBrains, incident.io, ssh-wingman)
- Work-specific MCPs are conditionally included based on username
- Custom MCPs installed via personal Homebrew tap: `conallob/tap`

## dot_vim — Vim Configuration

The Vim configuration lives in `dot_vim/` (deployed to `~/.vim/`) and uses vim-plug for plugin management.

### After any config change, apply and install

```bash
chezmoi apply ~/.vim/vimrc
vim +PlugInstall +qall      # install/update plugins
```

### Sanity-check: Go LSP (3-step manual test)

Create a throwaway file and verify the three core features:

```bash
mkdir -p /tmp/gotest && cd /tmp/gotest && go mod init gotest
vim main.go
```

**Step 1 – Completions + struct field completion**
```go
package main

import "fmt"

type Person struct {
    Name string `json:"name"`
    Age  int    `json:"age"`
}

func main() {
    p := Person{}
    fmt.Println(p.  // type p. then wait — gopls should show Name, Age
}
```
In insert mode, type `p.` and wait ~300 ms for the completion menu. You should see `Name` and `Age` from gopls.

**Step 2 – Signature help on `(`**
On the `fmt.Println(` line, enter insert mode and type `fmt.Println(`. The status line or a popup should display the function signature. If not, run `:LspStatus` and check gopls is running.

**Step 3 – goimports on save**
Delete the `import "fmt"` line, save (`:w`). On save, gopls runs `source.organizeImports` then `LspDocumentFormatSync` — the import should be re-added automatically. Confirm with `:!cat main.go`.

### Key LSP bindings (Go and all LSP-enabled files)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K`  | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `[g` / `]g` | Prev/next diagnostic |

### Snippet engine (UltiSnips)

Snippets live in `dot_vim/UltiSnips/`. Trigger with `<C-e>`, jump with `<C-j>`/`<C-k>`.
Common Go snippets: `iferr`, `handler`, `marshal`, `unmarshal`, `readfile`, `test`.

### REST client (vim-rest-console)

Create a `requests.rest` file, write an HTTP request, press `<localleader>rr` (`\rr` by default) to execute:

```
GET http://localhost:8080/health HTTP/1.1
```

Response appears in a split buffer, auto-formatted as JSON.

## Important Files

- **Brewfile**: Package dependencies for macOS (Homebrew bundle)
- **dot_zshrc**: Main ZSH initialization
- **dot_p10k.zsh**: Powerlevel10k theme configuration
- **shell.d/**: Shared shell environment and aliases
- **ssh/**: SSH configuration fragments
- **Library/private_Application Support/private_Claude/**: Claude Desktop MCP server configuration

## Platform-Specific Notes

### macOS (Darwin)
- Uses Homebrew at `/opt/homebrew/`
- Integrates with 1Password CLI plugins
- Custom SSH function in `zshrc.Darwin` to copy ghostty termcap to new hosts
- Enables atuin, powerlevel10k, and zsh-autosuggestions

### Dependencies
Installed via Brewfile:
- **Core tools**: chezmoi, git, jq, yq, pssh
- **Languages**: go, python@3.12
- **Container/K8s**: podman, kubectl, k9s, kubectx, krew, kustomize
- **Terminal**: ghostty, zellij
- **Shell**: atuin, powerlevel10k, zsh-autosuggestions
- **AI**: Claude desktop app
