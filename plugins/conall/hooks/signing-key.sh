#!/bin/bash
# SessionStart hook: in cloud sessions of my conall@andromeda.ai Claude account, sign commits with my GPG key.
# The setup script cannot read the environment's variables and the tool's shell skips ~/.bashrc,
# so this is the one place that sees CLAUDE_AI_GPG_KEY. It always exits 0 so it never blocks a session.
[ "${CLAUDE_CODE_REMOTE:-}" = true ] || exit 0
# Only my work Claude account, matched exactly (and case-insensitively), not the whole domain
[ "${CLAUDE_CODE_USER_EMAIL,,}" = conall@andromeda.ai ] || exit 0
[ -n "${CLAUDE_AI_GPG_KEY:-}" ] || exit 0

# Import the key (base64 of `gpg --armor --export-secret-keys`) when the keyring has no secret key
if ! gpg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
  printf '%s' "$CLAUDE_AI_GPG_KEY" | base64 -d | gpg --batch --import >/dev/null 2>&1 \
    || echo "signing-key: could not import CLAUDE_AI_GPG_KEY" >&2
fi

# Sign with the last primary secret key listed, whatever its ID, so rotating the key needs no edit here
key=$(gpg --list-secret-keys --with-colons 2>/dev/null \
  | awk -F: '/^sec/{primary=1} /^fpr/ && primary{fingerprint=$10; primary=0} END{print fingerprint}')
[ -n "$key" ] || exit 0

# Global config, not GIT_CONFIG_*: the harness resets those for every command
git config --global gpg.format openpgp
git config --global user.signingkey "$key"
exit 0
