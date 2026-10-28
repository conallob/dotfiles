#!/bin/bash
# Provision a Claude Code cloud VM with my personal skills and preferences.
# Run as root from the bootstrap in cloud/README.md, which clones this repo first.
# A non-zero exit fails session startup, so this script always exits 0.

repo_dir=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p ~/.claude
cp "$repo_dir/cloud/CLAUDE.md" ~/.claude/CLAUDE.md || echo "setup: could not install CLAUDE.md"

# Pick up the shared git and shell settings from the clone. include.path keeps the VM's own
# ~/.gitconfig (identity, harness signing key) intact.
git config --global --get-all include.path | grep -qxF "$repo_dir/cloud/gitconfig.claude-ai" \
  || git config --global --add include.path "$repo_dir/cloud/gitconfig.claude-ai" \
  || echo "setup: could not include gitconfig.claude-ai"
bashrc_line=". \"$repo_dir/cloud/bashenv.claude-ai\""
grep -qxF "$bashrc_line" ~/.bashrc 2>/dev/null \
  || echo "$bashrc_line" >> ~/.bashrc \
  || echo "setup: could not hook bashenv.claude-ai into ~/.bashrc"

# Register the clone itself as a local marketplace. Adding conallob/dotfiles from
# GitHub would also clone its submodules, including the private dot_ssh, and fail.
if command -v claude >/dev/null 2>&1 \
  && claude plugin marketplace add "$repo_dir" \
  && claude plugin install conall@conallob-dotfiles; then
  echo "setup: installed conall@conallob-dotfiles"
else
  echo "setup: plugin install failed, copying skills into ~/.claude/skills instead"
  mkdir -p ~/.claude/skills
  cp -rL "$repo_dir/dot_claude/skills/." ~/.claude/skills/ || echo "setup: could not copy skills"
fi

exit 0
