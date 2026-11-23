#!/bin/bash
#
# Claude-code-env.sh - load my shell environment into a Claude Code cloud session.
#
# Meant to be fetched and evaluated as a session startup script, e.g.
#   eval "$(curl -fsSL https://raw.githubusercontent.com/conallob/dotfiles/main/Claude-code-env.sh)"
# or sourced from ~/.bashrc. It must not exit the calling shell, so it never calls `exit`.
#
# Sources, in order, from shell.d/ in the dotfiles clone:
#   env.claude-ai                  common to every Claude Code session
#   env.claude-ai.<login username> optional, for the user the session runs as
#
# If CLAUDE_ENV_FILE is set (SessionStart hooks), the sourced files are also appended to it
# so the variables reach the commands Claude runs, not just this shell.
#
# Env vars:
#   CLAUDE_DOTFILES_DIR - clone to load from when this script is not run from one
#                         (default: /opt/conallob-dotfiles, where cloud/setup.sh clones it)

claude_code_env() {
  local self dir user f
  self="${BASH_SOURCE[0]:-}"
  if [ -n "$self" ] && [ -d "$(dirname "$self")/shell.d" ]; then
    dir=$(cd "$(dirname "$self")" && pwd)
  else
    dir="${CLAUDE_DOTFILES_DIR:-/opt/conallob-dotfiles}"
  fi
  if [ ! -d "$dir/shell.d" ]; then
    echo "Claude-code-env: no shell.d in $dir" >&2
    return 0
  fi

  user=$(id -un 2>/dev/null || echo "${USER:-}")
  for f in "$dir/shell.d/env.claude-ai" ${user:+"$dir/shell.d/env.claude-ai.$user"}; do
    [ -r "$f" ] || continue
    # shellcheck disable=SC1090
    . "$f"
    if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
      printf '. "%s"\n' "$f" >>"$CLAUDE_ENV_FILE"
    fi
  done
  return 0
}

claude_code_env
unset -f claude_code_env
