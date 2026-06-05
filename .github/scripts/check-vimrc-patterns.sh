#!/usr/bin/env bash
# Grep-based antipattern checks for the vimrc.
# Each check targets a class of bug that has caused real breakage in this repo.
# Run: bash .github/scripts/check-vimrc-patterns.sh dot_vim/vimrc
set -euo pipefail

VIMRC="${1:?Usage: $0 <vimrc-path>}"
fail=0

pass() { echo "  OK"; }
fail() { echo "  FAIL: $*"; fail=1; }

# ── Check 1: unconditional clipboard= setting ─────────────────────────────────
# 'set clipboard=unnamedplus' without a has() guard silently does nothing on vim
# builds without +clipboard or on systems with no X11/Wayland, breaking all
# yank/paste to the system register.
echo "→ clipboard= must be conditional on has()"
if grep -Pn '^set clipboard=' "$VIMRC"; then
  fail "wrap in: if has('unnamedplus') ... elseif has('clipboard') ... endif"
else
  pass
fi

# ── Check 2: exists('g:loaded_*') guard antipattern ──────────────────────────
# vim-plug's plug#end() adds plugins to &runtimepath but does not source their
# plugin/*.vim files during vimrc execution — that happens afterward. So
# g:loaded_<plugin> is always unset at vimrc parse time, making this guard a
# permanent no-op. Use exists(':CommandName') == 2 or autocmd VimEnter instead.
echo "→ exists('g:loaded_*') guard is unreliable at parse time"
if grep -n "exists('g:loaded_" "$VIMRC"; then
  fail "use exists(':CommandName') == 2 or autocmd VimEnter * ..."
else
  pass
fi

# ── Check 3: neovim-only lua calls without has('nvim') guard ─────────────────
# 'lua vim.*' is neovim-only. In regular vim it raises an error even with
# silent! (the error is suppressed but the Lua runtime is never available).
# Must be inside an 'if has("nvim") ... endif' block.
echo "→ 'lua vim.*' calls must be guarded by has('nvim')"
if awk '
  /if has\('"'"'nvim'"'"'\)/ { depth++ }
  /^[[:space:]]*endif/ && depth > 0 { depth-- }
  /lua vim\./ && depth == 0 {
    printf "  %s:%d: lua vim.* outside has('"'"'nvim'"'"') guard\n", FILENAME, NR
    found = 1
  }
  END { exit (found ? 1 : 0) }
' "$VIMRC"; then
  pass
else
  fail "wrap in: if has('nvim') ... endif"
fi

# ── Check 4: vim-ai partial configuration ────────────────────────────────────
# vim-ai's :AI and :AIEdit commands use g:vim_ai_complete and g:vim_ai_edit
# for their config. If only g:vim_ai_chat is set, the other two fall back to
# the built-in OpenAI defaults and emit a startup warning when OPENAI_API_KEY
# is not set — even if you're exclusively using the Anthropic endpoint.
echo "→ vim-ai: all three g:vim_ai_* configs must be set together"
if grep -q 'vim-ai' "$VIMRC"; then
  ai_ok=1
  for var in g:vim_ai_complete g:vim_ai_edit g:vim_ai_chat; do
    if ! grep -q "let $var\b" "$VIMRC"; then
      echo "  FAIL: $var not defined — causes OpenAI startup warning"
      ai_ok=0
      fail=1
    fi
  done
  [ "$ai_ok" -eq 1 ] && pass
else
  echo "  OK (vim-ai not present)"
fi

# ── Check 5: Go format-on-save conflict ──────────────────────────────────────
# If ALE has go in ale_fixers AND LspDocumentFormatSync is in BufWritePre,
# Go files get formatted twice (ALE gofmt/goimports + gopls), causing
# flickering and potential ordering issues.
# Note: gofmt in ale_linters is fine — linters only report errors, not reformat.
echo "→ Go format-on-save: ALE fixers must not include gofmt/goimports when LSP formats"
lsp_has_format=$(grep -c 'LspDocumentFormatSync\|LspCodeActionSync' "$VIMRC" 2>/dev/null || true)
if [ "$lsp_has_format" -gt 0 ]; then
  # Use awk to check specifically inside the ale_fixers dict (not ale_linters)
  if awk '
    /let g:ale_fixers/ { in_fixers = 1; next }
    in_fixers && /^let / { in_fixers = 0 }
    in_fixers && /'"'"'go'"'"'/ && (/gofmt/ || /goimports/) {
      printf "  %s:%d: go in ale_fixers with gofmt/goimports\n", FILENAME, NR
      found = 1
    }
    END { exit (found ? 1 : 0) }
  ' "$VIMRC"; then
    pass
  else
    fail "remove gofmt/goimports from go in g:ale_fixers — gopls handles format via LspDocumentFormatSync"
  fi
else
  echo "  OK (no LSP format on save configured)"
fi

echo ""
if [ "$fail" -ne 0 ]; then
  echo "vimrc antipattern checks FAILED"
  exit 1
fi
echo "All antipattern checks passed."
