#!/bin/bash
# Provision a Claude Code cloud VM with my personal skills and preferences.
# Run as root from the bootstrap in cloud/README.md, which clones this repo first.
# A non-zero exit fails session startup, so this script always exits 0.

repo_dir=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p ~/.claude
cp "$repo_dir/cloud/CLAUDE.md" ~/.claude/CLAUDE.md || echo "setup: could not install CLAUDE.md"

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
