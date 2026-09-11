#!/usr/bin/env bash
#
# assimilate.sh - bootstrap a new machine with this dotfiles repository.
#
# Checks that the required tooling (Homebrew, git) is present, applies the
# Brewfile to install/update all packages, applies dotfiles via chezmoi, and
# registers/syncs atuin shell history.
#
# Usage:
#   ./assimilate.sh                    (run from within a clone of this repo)
#   curl -fsSL <raw-url>/assimilate.sh | bash
#     - one-shot mode: clones the repo (default: to ~/dotfiles, override with
#       DOTFILES_DIR) and re-execs itself from inside the clone.
#
# Env vars (one-shot mode only):
#   DOTFILES_REPO - git URL to clone (default: https://github.com/conallob/dotfiles.git)
#   DOTFILES_DIR  - where to clone it (default: $HOME/dotfiles)

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/conallob/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Documents/Github/dotfiles}"

log() {
  printf '==> %s\n' "$1"
}

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "'${cmd}' is required but not installed. ${hint}"
  fi
  log "found ${cmd}: $(command -v "$cmd")"
}

install_homebrew() {
  log "Homebrew not found; installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Homebrew installs to different prefixes depending on platform/arch.
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$brew_bin" ]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done
}

# Resolves to this script's directory when it's running from a real file on
# disk (e.g. './assimilate.sh'), or nothing when it isn't (e.g. piped in via
# 'curl ... | bash', where $BASH_SOURCE doesn't point at a readable file).
resolve_script_dir() {
  local source="${BASH_SOURCE[0]:-}"
  if [ -n "$source" ] && [ -f "$source" ]; then
    cd "$(dirname "$source")" && pwd
  fi
}

# One-shot mode: clone (or update) this repo, then hand off to the copy's
# own assimilate.sh so the rest of the run has a Brewfile to work with.
bootstrap_clone_and_reexec() {
  require_cmd git "Install git first (e.g. via 'xcode-select --install' on macOS), then re-run."

  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "dotfiles already cloned at ${DOTFILES_DIR}; pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only
  elif [ -e "$DOTFILES_DIR" ]; then
    fail "${DOTFILES_DIR} already exists and isn't a git repository. Set DOTFILES_DIR to choose another location."
  else
    log "Cloning ${DOTFILES_REPO} into ${DOTFILES_DIR}..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  exec bash "${DOTFILES_DIR}/assimilate.sh" "$@"
}

main() {
  case "$(uname -s)" in
    Darwin|Linux)
      ;;
    *)
      fail "unsupported platform: $(uname -s). This script supports macOS and Linux."
      ;;
  esac

  local script_dir
  script_dir="$(resolve_script_dir)"
  if [ -z "$script_dir" ] || [ ! -f "$script_dir/Brewfile" ]; then
    bootstrap_clone_and_reexec "$@"
  fi
  BREWFILE="$script_dir/Brewfile"

  if ! command -v brew >/dev/null 2>&1; then
    install_homebrew
  fi
  require_cmd brew "Install it manually from https://brew.sh"
  require_cmd git "Install it with 'brew install git' and re-run this script."

  tap_custom_taps

  log "Applying Brewfile (this may take a while)..."
  brew bundle --file="$BREWFILE" install

  post_brewfile_setup

  log "Applying dotfiles via chezmoi..."
  chezmoi init --apply conallob

  setup_atuin

  log "Done."
}

# The tap to auto-trust without asking: this is the author's own tap, as
# opposed to third-party taps (e.g. ricardodantas/tap) that just happen to
# be in the Brewfile too.
AUTO_TRUST_TAP="conallob/tap"

# 'brew bundle' can choke on custom taps it hasn't seen before (e.g.
# conallob/tap) unless they're already tapped, so tap everything the
# Brewfile references up front. Homebrew >= 6.0 also requires non-official
# taps to be explicitly trusted via 'brew trust' before their formulae/casks
# can be loaded; only AUTO_TRUST_TAP is trusted automatically here, since
# that's this repo's own tap -- everything else is left for the user to
# trust deliberately (older Homebrew has no 'trust' command, so that step
# is skipped there too).
tap_custom_taps() {
  local tap trust_output
  while IFS= read -r tap; do
    [ -z "$tap" ] && continue
    log "Tapping ${tap}..."
    brew tap "$tap"

    if [ "$tap" != "$AUTO_TRUST_TAP" ]; then
      continue
    fi

    log "Trusting ${tap}..."
    if ! trust_output=$(brew trust --tap "$tap" 2>&1); then
      if printf '%s' "$trust_output" | grep -qi 'unknown command'; then
        log "brew trust not available in this Homebrew version; skipping explicit trust for ${tap}."
      else
        printf '%s\n' "$trust_output" >&2
        fail "brew trust --tap ${tap} failed"
      fi
    fi
  done < <(grep -oE '^tap "[^"]+"' "$BREWFILE" | sed -E 's/^tap "([^"]+)"/\1/')
}

# Registers this machine's atuin client (shell history sync) and syncs it.
# 'atuin register' prompts for a password interactively, so it only does
# anything useful in a real terminal -- skip it if we're already logged in,
# or just report a failure (e.g. no tty, already registered elsewhere)
# rather than aborting the whole bootstrap over it.
setup_atuin() {
  if ! command -v atuin >/dev/null 2>&1; then
    log "atuin not installed; skipping shell history sync setup."
    return
  fi

  if [ -f "$HOME/.local/share/atuin/session" ]; then
    log "atuin already registered; syncing..."
    atuin sync
    return
  fi

  log "Registering atuin account (conall)..."
  if atuin register -u conall; then
    atuin sync
  else
    log "atuin register failed (no tty, or already registered?). Run 'atuin login -u conall' manually, then 'atuin sync'."
  fi
}

# A few Brewfile entries need follow-up steps beyond 'brew bundle install',
# as noted in the Brewfile's own comments.
post_brewfile_setup() {
  # rustup: "run `rustup-init` after install"
  if command -v rustup-init >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
    log "Initializing rustup toolchain..."
    rustup-init -y --no-modify-path
  fi

  # ifttt-lint: "No Homebrew formula — install via: cargo install ifttt-lint"
  if ! command -v ifttt-lint >/dev/null 2>&1; then
    if command -v cargo >/dev/null 2>&1; then
      log "Installing ifttt-lint via cargo..."
      cargo install ifttt-lint
    else
      log "Skipping ifttt-lint: cargo not on PATH yet. Run 'cargo install ifttt-lint' after opening a new shell."
    fi
  fi
}

main "$@"
