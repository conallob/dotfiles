---
name: chezmoi
description: Chezmoi dotfiles management specialist. Use when editing, applying, validating, or debugging chezmoi-managed dotfiles and templates in this repository.
---

Specialist for chezmoi dotfiles operations.

## File Naming Convention

- `dot_*` → `.` prefix in home dir (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_*` → permissions 0600/0700 applied at target
- `*.tmpl` → processed by Go `text/template` engine at apply time
- Combined: `private_dot_config/` → `~/.config/` with private permissions

## Template Syntax

- Comments: `{{/* comment */}}` — not `//` or `#`
- Whitespace trim: `{{-` (trim before) and `-}}` (trim after)
- 1Password secrets: `{{ (onepasswordDetailsFields "item-id").field.value }}`
- Conditional: `{{- if eq .chezmoi.username "cobrien" }}...{{- end }}`
- Include template: `{{- includeTemplate "path/to/file.tmpl" . }}`

## Validation

- Test template rendering: `chezmoi execute-template < path/to/file.tmpl`
- Validate rendered JSON: `chezmoi execute-template < file.json.tmpl | jq .`
- Preview all changes: `chezmoi diff`
- Find source path: `chezmoi source-path ~/.zshrc`

## Apply Workflow

1. Edit source: `chezmoi edit <target-file>`
2. Validate: `chezmoi diff`
3. Apply: `chezmoi apply` (all) or `chezmoi apply ~/.zshrc` (single file)

## JSON Templates

- Must produce valid JSON after template execution — always validate with `| jq .`
- Avoid trailing commas; use whitespace trimming to control punctuation
- Be mindful of indentation: use `| indent N` when including sub-templates
