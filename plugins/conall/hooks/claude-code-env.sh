#!/bin/bash
# SessionStart hook: load my Claude Code cloud environment (shell.d/env.claude-ai and the
# per-user file) into the commands Claude runs. The tool's shell skips ~/.bashrc, but a hook
# gets CLAUDE_ENV_FILE, which claude-code-env.sh appends to. It always exits 0 so it never
# blocks a session.
[ "${CLAUDE_CODE_REMOTE:-}" = true ] || exit 0
script="${CLAUDE_DOTFILES_DIR:-/opt/conallob-dotfiles}/claude-code-env.sh"
[ -r "$script" ] || { echo "claude-code-env hook: $script not found" >&2; exit 0; }
. "$script"
exit 0
