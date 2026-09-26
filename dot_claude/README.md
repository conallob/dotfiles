# Claude Configuration

This directory contains unified configuration for both **Claude Code** (CLI) and **Claude Desktop** (GUI application).

## Configuration Files

### Main Configurations

| File | Purpose | Used By |
|------|---------|---------|
| `config.json.tmpl` | MCP servers + LSP configuration | Claude Code (CLI) |
| `settings.json.tmpl` | Basic CLI settings | Claude Code (CLI) |
| `plugins/config.json.tmpl` | Plugin-specific settings | Claude Code plugins |
| `../Library/.../claude_desktop_config.json.tmpl` | MCP server configuration | Claude Desktop (GUI) |

### Shared MCP Server Templates

| File | Description |
|------|-------------|
| `mcp-servers-personal.json.tmpl` | Personal & third-party MCP servers (always included) |
| `mcp-servers-work.json.tmpl` | Work-specific MCP servers (included when `isWorkAccount` is true) |

## Architecture

The configuration uses a **unified template approach** where MCP server definitions are maintained once and shared across both Claude Code and Claude Desktop:

```
┌─────────────────────────────────────────────────────────┐
│         Shared MCP Server Definitions                   │
├─────────────────────────────────────────────────────────┤
│  • mcp-servers-personal.json.tmpl                       │
│    - obsidian-mcp-tools                                 │
│    - home-assistant-taku                                │
│    - jetbrains                                          │
│    - omnifocus                                          │
│    - google-sheets                                      │
│    - ssh-wingman                                        │
│                                                         │
│  • mcp-servers-work.json.tmpl (conditional)            │
│    - incidentio                                         │
│    - GitLab                                             │
└─────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌──────────────────┐          ┌──────────────────────┐
│  Claude Code     │          │  Claude Desktop      │
│  config.json     │          │  claude_desktop_     │
│                  │          │  config.json         │
├──────────────────┤          ├──────────────────────┤
│  mcpServers: {   │          │  mcpServers: {       │
│    {{personal}}  │          │    {{personal}}      │
│    {{work}}      │          │    {{work}}          │
│  }               │          │  }                   │
└──────────────────┘          └──────────────────────┘
```

## MCP Server Definitions

### Personal Servers (Always Included)

- **obsidian-mcp-tools**: Obsidian integration with 1Password API key
- **home-assistant-taku**: Home Assistant integration via mcp-proxy
- **jetbrains**: JetBrains IDE integration (GoLand)
- **omnifocus**: OmniFocus task management
- **google-docs** / **google-sheets**: Google Workspace remote MCP servers (registered by a run script, see below)
- **ssh-wingman**: SSH session management

### Work Servers (Included when `isWorkAccount` is true)

- **incidentio**: Incident.io integration with 1Password API key
- **GitLab**: GitLab MCP HTTP integration

### Google Workspace MCP Servers (Docs, Sheets)

Google's first-party remote MCP servers (Developer Preview), authenticated as
conall@gmail.com through an OAuth client in the GCP project
`agentic-workspace-hooks` (the same project used for the Cloudflare OAuth
credentials).

| Server | URL |
|--------|-----|
| `google-docs` | `https://docsmcp.googleapis.com/mcp/v1` |
| `google-sheets` | `https://sheetsmcp.googleapis.com/mcp/v1` |

These are **not** in the `mcp-servers-*.json.tmpl` partials: Claude Code keeps
an OAuth client secret in the system keychain rather than `~/.claude.json`, and
Claude Desktop only accepts remote servers as custom connectors. Instead,
`run_onchange_after_google-workspace-mcp.sh.tmpl` (non-work hosts only)
registers both with `claude mcp add-json --client-secret` (OAuth callback port
38917, scopes pinned to the ones below), reading the secret from 1Password at
run time. It
re-runs whenever the 1Password item changes.

#### One-time GCP setup

1. Enable the APIs and their MCP services:
   ```bash
   gcloud services enable \
     docs.googleapis.com docsmcp.googleapis.com \
     sheets.googleapis.com sheetsmcp.googleapis.com \
     drive.googleapis.com \
     --project=agentic-workspace-hooks
   ```
2. **Google Auth Platform → Data Access → Add or remove scopes → Manually add scopes**:
   ```
   https://www.googleapis.com/auth/drive.readonly
   https://www.googleapis.com/auth/drive.file
   https://www.googleapis.com/auth/documents.readonly
   https://www.googleapis.com/auth/documents
   https://www.googleapis.com/auth/spreadsheets.readonly
   https://www.googleapis.com/auth/spreadsheets
   ```
3. **Audience**: the app is External, so while it's in *Testing*, add
   conall@gmail.com as a test user. Refresh tokens for a Testing app expire
   after 7 days, so expect to re-authenticate weekly unless the app is published.
4. **Clients → Create client → Web application**, with authorized redirect URIs:
   - `http://localhost:38917/callback` (Claude Code)
   - `https://claude.ai/api/mcp/auth_callback` (Claude Desktop / claude.ai)
5. Save the client in 1Password as `google-workspace-mcp-oauth`, with
   `username` = client ID and `credential` = client secret.

#### Activate

```bash
chezmoi apply        # runs the registration script
claude               # then /mcp → google-docs / google-sheets → Authenticate
```

For Claude Desktop, add each server under **Settings → Connectors → Add custom
connector**, with the URL above and the same client ID/secret under *Advanced
settings*. Connectors sync to your claude.ai account, so there's no config file
to manage.

## LSP (Language Server Protocol) Configuration

Claude Code v2.0.74+ includes LSP support. The configuration uses the same language servers installed for Vim, providing consistent IDE features across both editors.

### Configured Language Servers

| Language Server | Languages | Features |
|----------------|-----------|----------|
| **gopls** | Go | Code completion, go-to-definition, diagnostics, refactoring |
| **basedpyright** | Python | Type checking, completion, diagnostics |
| **marksman** | Markdown | Completion, navigation, diagnostics |
| **yaml-language-server** | YAML | Schema validation, completion (GitHub Actions, GitLab CI, Docker Compose) |
| **texlab** | LaTeX, BibTeX | Completion, build support, navigation |
| **typescript-language-server** | TypeScript, JavaScript | Full TS/JS support, JSX/TSX |
| **vscode-json-language-server** | JSON, JSONC | Schema validation, completion |
| **bash-language-server** | Bash, Shell | Completion, diagnostics, shellcheck integration |

### LSP Features

- **Code Completion**: Intelligent suggestions based on context
- **Go to Definition**: Navigate to symbol definitions
- **Find References**: Find all usages of a symbol
- **Diagnostics**: Real-time error and warning detection
- **Hover Documentation**: View documentation on hover
- **Code Actions**: Quick fixes and refactoring suggestions
- **Formatting**: Auto-format on save

### Configuration Details

The LSP configuration in `config.json.tmpl` includes:

- **Root Pattern Detection**: Automatically detects project roots (e.g., `go.mod`, `package.json`, `.git`)
- **File Type Association**: Maps file extensions to appropriate language servers
- **Server-Specific Settings**: Optimized settings for each language server
- **YAML Schema Integration**: Automatic schema validation for GitHub Actions, GitLab CI, and Docker Compose files

### Installation

All language servers are installed via Homebrew (see Brewfile):

```bash
brew install gopls basedpyright marksman yaml-language-server texlab \
             typescript-language-server vscode-langservers-extracted \
             bash-language-server
```

Or install all dependencies at once:

```bash
brew bundle install
```

## Template Logic

### Conditional Inclusion

Work servers are only included when `isWorkAccount` is true — a `.chezmoitemplates/isWorkAccount` partial (read via `includeTemplate "isWorkAccount" .`, since `.chezmoidata.*` files don't support `.tmpl` templating) computed by checking whether the hostname starts with `andromeda` (case-insensitive):

```go
{{- if eq (includeTemplate "isWorkAccount" .) "true" }}
  // work servers included
{{- end }}
```

### Comma Handling

The templates use conditional comma insertion to ensure valid JSON:

```go
{{- includeTemplate "mcp-servers-personal.json.tmpl" . -}}
{{- if eq (includeTemplate "isWorkAccount" .) "true" }},{{ end -}}
{{- includeTemplate "mcp-servers-work.json.tmpl" . -}}
```

This ensures:
- **Personal only** (`isWorkAccount` is false): No trailing comma → Valid JSON ✓
- **Personal + Work** (`isWorkAccount` is true): Comma between them → Valid JSON ✓

## Adding New MCP Servers

### Personal Server

Edit `mcp-servers-personal.json.tmpl`:

```json
"new-server": {
  "command": "/path/to/command",
  "args": ["arg1", "arg2"],
  "env": {
    "API_KEY": "{{ (onepasswordDetailsFields \"item-id\").credential.value }}"
  }
},
```

**Note**: Do NOT add a trailing comma after the last server (ssh-wingman).

### Work Server

Edit `mcp-servers-work.json.tmpl`:

```json
{{- if eq (includeTemplate "isWorkAccount" .) "true" }}
"new-work-server": {
  "command": "/path/to/command"
},
"existing-work-servers": {
  ...
}
{{- end }}
```

**Note**: Do NOT add a trailing comma after the last work server.

## 1Password Integration

MCP servers that require API keys use 1Password integration:

```json
"env": {
  "API_KEY": "{{ (onepasswordDetailsFields \"op-item-id\").credential.value }}"
}
```

To find the 1Password item ID:
```bash
op item list
op item get "Item Name" --format json
```

## Testing Configuration

### Validate JSON Templates

```bash
# Test Claude Code config
chezmoi execute-template < dot_claude/config.json.tmpl | jq .

# Test Claude Desktop config
chezmoi execute-template < Library/private_Application\ Support/private_Claude/claude_desktop_config.json.tmpl | jq .
```

### Apply Configuration

```bash
# Preview changes
chezmoi diff ~/.claude/config.json
chezmoi diff ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Apply
chezmoi apply
```

## Troubleshooting

### Invalid JSON Error

If you get JSON parsing errors:
1. Check for trailing commas in the templates
2. Validate with `jq`:
   ```bash
   chezmoi execute-template < dot_claude/config.json.tmpl | jq .
   ```
3. Common issues:
   - Trailing comma when work servers are empty
   - Missing comma between personal and work servers
   - Unclosed braces or brackets

### MCP Server Not Loading

1. Check if the server command exists:
   ```bash
   which mcp-omnifocus
   ls -la /opt/homebrew/bin/mcp-*
   ```

2. Verify 1Password CLI authentication:
   ```bash
   op account list
   op read "op://Private/Item/field"
   ```

3. Check Claude logs:
   - **Claude Code**: Check terminal output
   - **Claude Desktop**: Check Console.app for "Claude" process

### Work Servers Not Appearing

Verify `isWorkAccount` resolves as expected:
```bash
hostname
chezmoi execute-template '{{ includeTemplate "isWorkAccount" . }}'
```

`isWorkAccount` is true when the hostname starts with `andromeda` (case-insensitive). If it should be true but isn't, check the hostname or update the prefix check in `.chezmoitemplates/isWorkAccount`.

## File Locations After Applying

| Template | Deployed To |
|----------|------------|
| `dot_claude/config.json.tmpl` | `~/.claude/config.json` |
| `dot_claude/settings.json.tmpl` | `~/.claude/settings.json` |
| `dot_claude/plugins/config.json.tmpl` | `~/.claude/plugins/config.json` |
| `Library/.../claude_desktop_config.json.tmpl` | `~/Library/Application Support/Claude/claude_desktop_config.json` |

## References

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [MCP Server Documentation](https://modelcontextprotocol.io/)
- [Chezmoi Templating](https://www.chezmoi.io/user-guide/templating/)
- [1Password CLI Integration](https://developer.1password.com/docs/cli/)
