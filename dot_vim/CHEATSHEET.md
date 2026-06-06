# Vim Cheat Sheet

> Leader key is `,` — so `<leader>w` means `,w`

---

## Files & Navigation

| Key | Action |
|-----|--------|
| `Ctrl-P` | Fuzzy find file in project |
| `,f` | Live grep (ripgrep) across project |
| `,b` | Switch between open buffers |
| `,t` | Search tags |
| `,h` | Recent files |
| `,m` | Marks |
| `,n` | Toggle file tree (NERDTree) |
| `,nf` | Reveal current file in tree |

---

## Splits & Windows

| Key | Action |
|-----|--------|
| `,tt` | Open terminal (horizontal split) |
| `,tv` | Open terminal (vertical split) |
| `Ctrl-H/J/K/L` | Move between splits (works inside terminal too) |
| `Esc` | Exit terminal mode |

---

## Buffers & Tabs

| Key | Action |
|-----|--------|
| `,bn` / `,bp` | Next / previous buffer |
| `,bd` | Close buffer |
| `,tn` | New tab |
| `,tc` | Close tab |
| `,th` / `,tl` | Previous / next tab |

---

## LSP (works in Go, Python, and any LSP-enabled file)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find all references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Hover docs |
| `,rn` | Rename symbol |
| `,ca` | Code action (fix, refactor, etc.) |
| `[g` / `]g` | Previous / next diagnostic |
| `gs` | Search symbols in file |
| `gS` | Search symbols in workspace |

---

## Completion

| Key | Action |
|-----|--------|
| `Tab` / `Shift-Tab` | Next / previous completion item |
| `Enter` | Accept completion |
| `Ctrl-E` | Expand snippet |
| `Ctrl-J` / `Ctrl-K` | Jump forward / backward in snippet |

---

## Debugger (vimspector + delve for Go)

> Start by setting a breakpoint with `F9`, then launch with `F5`.
> A `.vimspector.json` in the project root overrides the built-in Go configs.

| Key | Action |
|-----|--------|
| `F5` | Start / continue |
| `F9` | Toggle breakpoint |
| `F10` | Step over |
| `F11` | Step into |
| `F12` | Step out |
| `F3` | Stop |
| `F4` | Restart |
| `,di` | Inspect variable under cursor |

---

## Test Runner (vim-test)

| Key | Action |
|-----|--------|
| `,un` | Run test nearest to cursor |
| `,uf` | Run all tests in current file |
| `,us` | Run entire test suite |
| `,ul` | Re-run last test |

---

## Git

| Key | Action |
|-----|--------|
| `,gs` | Git status |
| `,gc` | Git commit |
| `,gp` | Git push |
| `,gl` | Git pull |
| `,gd` | Diff current file |
| `,gb` | Git blame |
| `,gh` | Open file on GitHub/GitLab |
| `[h` / `]h` | Previous / next changed hunk |
| `,hs` | Stage hunk |
| `,hu` | Undo hunk |
| `,hp` | Preview hunk diff |

---

## Go (vim-go extras, beyond LSP)

| Key | Action |
|-----|--------|
| `,gb` | Build |
| `,gr` | Run |
| `,gt` | Test |
| `,gc` | Toggle coverage |
| `,ga` | Alternate file (e.g. `foo.go` ↔ `foo_test.go`) |
| `,gd` | Open Go doc |
| `,gi` | Implement interface (GoImpl) |
| `,gf` | Fill struct fields |

---

## Multiple Cursors (vim-visual-multi)

| Key | Action |
|-----|--------|
| `Ctrl-N` | Select word under cursor; keep pressing to add next match |
| `Ctrl-↓` / `Ctrl-↑` | Add cursor below / above |
| `q` | Skip current match, go to next |
| `Q` | Remove current cursor |
| `Esc` | Exit multi-cursor mode |

---

## AI (vim-ai — requires `ANTHROPIC_API_KEY`)

| Key | Action |
|-----|--------|
| `,ai` | AI complete / answer (normal or visual) |
| `,ae` | AI edit selection |
| `,ac` | Open AI chat |
| `,at` | Toggle AI on/off |

---

## REST Client (vim-rest-console)

Open a `.rest` or `.http` file, write a request, then:

| Key | Action |
|-----|--------|
| `\rr` | Execute request under cursor |

```
GET http://localhost:8080/health HTTP/1.1
```

---

## Searching & Editing

| Key | Action |
|-----|--------|
| `,/` | Clear search highlight |
| `,jf` | Format JSON buffer (via jq) |
| `,ss` | Toggle spell check |
| `,sn` / `,sp` | Next / previous misspelling |
| `,s?` | Suggest spelling corrections |
| `,=` | Re-indent entire file |
| `F2` | Toggle paste mode |

---

## Vimrc

| Key | Action |
|-----|--------|
| `,ev` | Edit vimrc in a split |
| `,sv` | Reload vimrc |
| `,w` / `,q` / `,x` | Save / quit / save-and-quit |
