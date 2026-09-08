#!/usr/bin/env bash
#
# assimilate.sh - bootstrap a new machine with this dotfiles repository.
#
# Checks that the required tooling (Homebrew, git, chezmoi) is present,
# then applies the Brewfile to install/update all packages.
#
# Usage: ./assimilate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="${SCRIPT_DIR}/Brewfile"

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

main() {
  case "$(uname -s)" in
    Darwin|Linux)
      ;;
    *)
      fail "unsupported platform: $(uname -s). This script supports macOS and Linux."
      ;;
  esac

  if ! command -v brew >/dev/null 2>&1; then
    install_homebrew
  fi
  require_cmd brew "Install it manually from https://brew.sh"
  require_cmd git "Install it with 'brew install git' and re-run this script."

  if [ ! -f "$BREWFILE" ]; then
    fail "Brewfile not found at ${BREWFILE}"
  fi

  log "Applying Brewfile (this may take a while)..."
  brew bundle --file="$BREWFILE" install

  log "Done. Run 'chezmoi init --apply <your-github-username>' if you haven't already applied your dotfiles."
}

main "$@"
