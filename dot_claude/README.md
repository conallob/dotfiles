# Claude Configuration

This directory contains unified configuration for both **Claude Code** (CLI) and **Claude Desktop** (GUI application).

## Configuration Files

### Main Configurations

| File | Purpose | Used By |
|------|---------|---------|
| `config.json.tmpl` | MCP server configuration | Claude Code (CLI) |
| `settings.json.tmpl` | Basic CLI settings | Claude Code (CLI) |
| `plugins/config.json.tmpl` | Plugin-specific settings | Claude Code plugins |
| `../Library/.../claude_desktop_config.json.tmpl` | MCP server configuration | Claude Desktop (GUI) |

### Shared MCP Server Templates

| File | Description |
|------|-------------|
| `mcp-servers-personal.json.tmpl` | Personal & third-party MCP servers (always included) |
| `mcp-servers-work.json.tmpl` | Work-specific MCP servers (included when `username == "cobrien"`) |

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
- **google-sheets**: Google Sheets integration
- **ssh-wingman**: SSH session management

### Work Servers (Included for user "cobrien")

- **incidentio**: Incident.io integration with 1Password API key
- **GitLab**: GitLab MCP HTTP integration

## Template Logic

### Conditional Inclusion

Work servers are only included when the username is "cobrien":

```go
{{- if eq .chezmoi.username "cobrien" }}
  // work servers included
{{- end }}
```

### Comma Handling

The templates use conditional comma insertion to ensure valid JSON:

```go
{{- includeTemplate "mcp-servers-personal.json.tmpl" . -}}
{{- if eq .chezmoi.username "cobrien" }},{{ end -}}
{{- includeTemplate "mcp-servers-work.json.tmpl" . -}}
```

This ensures:
- **Personal only** (username ≠ "cobrien"): No trailing comma → Valid JSON ✓
- **Personal + Work** (username = "cobrien"): Comma between them → Valid JSON ✓

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
{{- if eq .chezmoi.username "cobrien" }}
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

Verify your username matches the condition:
```bash
echo $USER
chezmoi data | jq .chezmoi.username
```

If it should be "cobrien" but isn't, update your chezmoi configuration.

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
