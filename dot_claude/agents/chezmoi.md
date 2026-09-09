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
- Conditional: `{{- if eq (includeTemplate "isWorkAccount" .) "true" }}...{{- end }}` — `isWorkAccount` is a `.chezmoitemplates/isWorkAccount` partial based on whether the hostname starts with `andromeda` (case-insensitive)
- Include template: `{{- includeTemplate "path/to/file.tmpl" . }}`

## Chezmoi Template Data Gotchas

- `.chezmoidata.<format>` files are **static only** — no `.tmpl` suffix support. A file named `.chezmoidata.toml.tmpl` is not read as data at all; it's treated (and applied) as a regular dotfile template instead. For anything computed (e.g. from `.chezmoi.hostname`), put it in a `.chezmoitemplates/<name>` partial and read it back with `includeTemplate "<name>" .` (returns a string).
- `dot_config/chezmoi/chezmoi.toml.tmpl` renders only on `chezmoi init`, never on `apply`/`update` — an existing install's `chezmoi.toml` won't pick up changes there without re-init. Don't put per-run logic other templates depend on there.
- `chezmoi execute-template < file` (what CI uses) only evaluates that one file — confirm any new data mechanism actually resolves under this exact invocation, not just under `apply`/`update`.

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
