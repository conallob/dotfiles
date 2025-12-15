# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

his is a **chezmoi-managed dotfiles repository** for managing personal configuration across macOS, FreeBSD, and Linux systems. The repository uses chezmoi's templating system with 1Password integration for secrets management.

## Key Architecture Patterns

### Chezmoi Naming Convention

Files and directories use chezmoi's special prefix naming:
- `dot_*` → becomes `.` in the home directory (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_*` → file permissions set to private (0600 or 0700)
- Combined: `private_Application Support/private_Claude` → `~/.config/Application Support/Claude/` with appropriate permissions

### Template System

Files with `.tmpl` extension are processed by chezmoi using Go templates:
- **1Password Integration**: Uses `onepasswordDetailsFields` and `onepasswordDocument` functions to inject secrets
- **Conditional Logic**: `{{- if eq .chezmoi.username "cobrien" }}` gates work-specific configurations
- **Comments in JSON**: Uses `"_comment"` keys (not `"$comment"`) for annotations in JSON files, as per recent commits

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

### Claude Desktop MCP Configuration

The main MCP configuration is at `Library/private_Application Support/private_Claude/claude_desktop_config.json.tmpl`:
- Contains multiple MCP servers (Obsidian, OmniFocus, Home Assistant, JetBrains, incident.io, ssh-wingman)
- Work-specific MCPs are conditionally included based on username
- Custom MCPs installed via personal Homebrew tap: `conallob/tap`

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
