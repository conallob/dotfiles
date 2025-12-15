# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository managed by **chezmoi** (v2.67.1+), a dotfile management tool that uses Go templates and supports integration with 1Password for secret management. The repository manages shell configurations, application settings, and system preferences across multiple platforms (primarily macOS and FreeBSD).

## Key Architecture

### Chezmoi Integration

All dotfile management uses chezmoi:
- Source directory is managed by chezmoi - never edit files in the home directory directly
- Use `chezmoi edit <file>` to modify dotfiles
- Use `chezmoi apply` to deploy changes to the home directory
- Chezmoi is configured to auto-commit changes (see dot_config/chezmoi/chezmoi.toml.tmpl:2)

### File Naming Convention

Chezmoi uses special prefixes to control file deployment:
- `dot_` prefix becomes `.` in the home directory (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` prefix sets restrictive permissions and excludes from git diffs
- `.tmpl` suffix indicates Go template files that are processed during apply

### Shell Configuration Architecture

The shell configuration uses a multi-layered approach:

1. **Primary entry point**: dot_zshrc (line 34-39) sources platform and host-specific configurations
2. **Platform-specific**: dot_zsh/zshrc.$(uname -s) for OS-specific setup (Darwin, FreeBSD)
3. **Shared configuration**: shell.d/ directory contains shell-agnostic configs:
   - `shell.d/env` - environment variables
   - `shell.d/alias` - command aliases
   - Platform-specific overrides: `env.Darwin`, `alias.Darwin`, etc.
   - Host-specific overrides: `env.$(hostname -s)`, `alias.$(hostname -s)`, etc.

### 1Password Secret Management

Secrets are managed via 1Password CLI integration:
- Chezmoi config uses 1Password account "conall@taku.ie" (dot_config/chezmoi/chezmoi.toml.tmpl:6)
- Template files use `onepasswordDetailsFields` function to inject secrets
- Example in Library/private_Application Support/private_Claude/claude_desktop_config.json.tmpl

### MCP Server Configuration

Claude Desktop MCP servers are configured in Library/private_Application Support/private_Claude/claude_desktop_config.json.tmpl:
- Personal MCPs: omnifocus, google-sheets, ssh-wingman (all from conallob/tap homebrew tap)
- Work MCPs: incidentio (only deployed when username is "cobrien")
- Third-party: Obsidian, Home Assistant, JetBrains GoLand integration

## Development Commands

### Managing Dotfiles

```bash
# Edit a dotfile in the chezmoi source directory
chezmoi edit ~/.zshrc

# Apply changes from source to home directory
chezmoi apply

# View differences between source and deployed files
chezmoi diff

# Add a new file to chezmoi management
chezmoi add <file>

# Get the source path for investigation
chezmoi source-path
```

### Testing Changes

When modifying shell configurations:
```bash
# Test zsh configuration
zsh -n ~/.zshrc  # Check for syntax errors

# Reload shell configuration
source ~/.zshrc
```

### Working with 1Password Secrets

To view how templates will be processed:
```bash
# Preview what will be applied
chezmoi execute-template < file.tmpl

# Apply with verbose output to debug template issues
chezmoi apply -v
```

## Important Conventions

### Shell Environment

- The `$CONFIGS` variable points to the source shell.d directory (shell.d/env:8)
- Shell configurations support Darwin (macOS), FreeBSD, and Linux
- ssh-agent configuration is currently disabled (shell.d/env:21)
- Atuin is used for shell history synchronization (dot_zshrc:31)

### SSH Configuration

- SSH configs are managed in a separate git submodule (dot_ssh) from github.com/conallob/ssh
- Legacy Python script at dot_ssh/coding/ssh_config_autogen/autogen_ssh_config.py (Python 2.7, appears unused)

### Platform-Specific Behavior

macOS (Darwin):
- Homebrew path: /opt/homebrew/bin
- Powerlevel10k theme via Homebrew
- 1Password CLI plugins loaded (dot_zsh/zshrc.Darwin:8)
- Custom ssh function that auto-copies ghostty termcap to new hosts (dot_zsh/zshrc.Darwin:11-17)

## Package Management

Primary package manager: Homebrew (see Brewfile)
- Development tools: Go, Python 3.12, Git
- IDEs: GoLand via JetBrains Toolbox
- Container tools: Podman with Podman Desktop
- Kubernetes: kubectl, krew, kustomize, k9s, kubectx
- Terminal: Ghostty
- Shell enhancements: atuin, powerlevel10k, zsh-autosuggestions, zellij

Custom Homebrew tap: conallob/tap (contains personally developed MCP servers)

## Testing Requirements

When modifying Python code (e.g., autogen_ssh_config.py), write unit tests following the project's existing patterns.
