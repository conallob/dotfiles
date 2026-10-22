# Cloud sessions

Cloud sessions (claude.ai/code, the Claude mobile app) run on a fresh VM that never sees
`~/.claude` or chezmoi. `setup.sh` gives that VM my skills and preferences from this repo.

## One-time setup

In claude.ai/code, edit the environment and paste this into **Setup script**:

```bash
#!/bin/bash
rm -rf /opt/conallob-dotfiles
git clone --depth 1 https://github.com/conallob/dotfiles /opt/conallob-dotfiles \
  && bash /opt/conallob-dotfiles/cloud/setup.sh
exit 0
```

It registers the clone as a local marketplace and installs the `conall` plugin (skills appear as
`/conall:<skill>`), and writes
`~/.claude/CLAUDE.md` from `CLAUDE.md` in this directory. If the plugin install fails it copies
`dot_claude/skills/` into `~/.claude/skills/` instead.

The clone is deliberately shallow and submodule-free. Adding `conallob/dotfiles` from GitHub as a
marketplace would also clone the private `dot_ssh` submodule, which a cloud VM can't read.

## Checking it worked

In a new cloud session, `/context` should list `/root/.claude/CLAUDE.md` under **Memory files**,
and the skills list should show the `conall:` skills.

## Updates

Anthropic caches the environment after setup for about a week, and reruns the script when the
cache expires or the script is edited. A change here reaches cloud sessions at the next rerun;
edit the pasted script (e.g. add a comment) to force one.

`CLAUDE.md` here is a hand-kept copy of the portable parts of `dot_claude/CLAUDE.md.tmpl`.
