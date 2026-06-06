# Vim Cheat Sheet

> Leader key is `,` — so `<leader>w` means `,w`

---

## Motion

| Key | Action |
|-----|--------|
| `w` / `b` | Next / previous word start |
| `e` / `ge` | Next / previous word end |
| `W` / `B` / `E` | Same but WORD (whitespace-delimited) |
| `0` / `^` / `$` | Line start (col 0) / first non-blank / end |
| `gg` / `G` | Top / bottom of file |
| `50G` or `:50` | Jump to line 50 |
| `%` | Jump to matching bracket / paren / `#ifdef` |
| `{` / `}` | Previous / next empty line (paragraph) |
| `Ctrl-D` / `Ctrl-U` | Half-page down / up |
| `H` / `M` / `L` | Top / middle / bottom of visible screen |
| `zz` / `zt` / `zb` | Scroll so cursor is middle / top / bottom |
| `f{c}` / `F{c}` | Jump to next / previous `{c}` on line |
| `t{c}` / `T{c}` | Jump *before* next / previous `{c}` on line |
| `;` / `,` | Repeat / reverse last `f`/`t` jump |
| `*` / `#` | Search forward / backward for word under cursor |
| `n` / `N` | Next / previous search match |
| `''` (two ticks) | Jump back to where you were before last big jump |
| `Ctrl-O` / `Ctrl-I` | Walk backward / forward through jump list |

---

## Text Objects — the vim superpower

> Pattern: `{operator}{scope}{object}` e.g. `ci"` = change inside quotes

| Object | Means |
|--------|-------|
| `iw` / `aw` | inner word / a word (includes space) |
| `i"` / `a"` | inside / around double quotes |
| `i'` / `a'` | inside / around single quotes |
| `i(` / `a(` | inside / around parentheses (also `)`) |
| `i{` / `a{` | inside / around braces (also `}`) |
| `i[` / `a[` | inside / around brackets |
| `it` / `at` | inside / around HTML/XML tag |
| `ip` / `ap` | inner / a paragraph |
| `is` / `as` | inner / a sentence |

**Common combos:**

| Command | Does |
|---------|------|
| `ciw` | Change word under cursor |
| `ci"` | Change text inside quotes |
| `ca(` | Change everything including the parentheses |
| `di{` | Delete inside braces |
| `yi[` | Yank inside brackets |
| `va"` | Visually select including the quotes |
| `=i{` | Re-indent inside braces |
| `gUiw` | Uppercase word |
| `guiw` | Lowercase word |

---

## Operators

| Key | Action |
|-----|--------|
| `d` | Delete (into default register) |
| `c` | Change (delete + enter insert mode) |
| `y` | Yank (copy) |
| `>` / `<` | Indent / dedent |
| `=` | Auto-indent |
| `gU` / `gu` | Uppercase / lowercase |
| `gc` | Toggle comment (NERDCommenter) — works on motion or visual |

All operators compose with text objects and motions: `d3j`, `y$`, `c%`, `>ip`.

---

## Insert Mode

| Key | Action |
|-----|--------|
| `i` / `a` | Insert before / after cursor |
| `I` / `A` | Insert at line start / end |
| `o` / `O` | New line below / above, enter insert |
| `s` / `S` | Delete char / line and insert |
| `C` | Change to end of line |
| `Ctrl-W` | Delete word backward (in insert mode) |
| `Ctrl-U` | Delete to start of line (in insert mode) |
| `Ctrl-R{reg}` | Paste register `{reg}` without leaving insert mode |
| `Ctrl-R=` | Insert result of expression (e.g. `Ctrl-R= 2+2 Enter` → `4`) |

---

## Registers

> Prefix any yank or paste with `"{reg}` to use a named register.

| Key | Action |
|-----|--------|
| `"ayy` | Yank line into register `a` |
| `"ap` | Paste from register `a` |
| `"+y` / `"+p` | Yank to / paste from system clipboard |
| `"0p` | Paste the last *yanked* text (not deleted) |
| `""p` | Paste from default register |
| `:reg` | Show all register contents |
| `Ctrl-R{reg}` | Paste register in insert / command mode |

**Special registers:**
- `"0` — last yank
- `"+` — system clipboard
- `"%` — current filename
- `":` — last command
- `"/` — last search
- `"_` — black hole (delete without clobbering clipboard)

---

## Macros

| Key | Action |
|-----|--------|
| `q{a}` | Start recording macro into register `a` |
| `q` | Stop recording |
| `@{a}` | Play macro `a` |
| `@@` | Replay last macro |
| `10@a` | Play macro `a` 10 times |
| `:reg a` | Inspect what's in macro `a` |

**Tip:** Record a macro that ends by moving to the next target line, then `10@@` to repeat across many lines.

---

## Search & Replace

| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all, confirm each |
| `:'<,'>s/old/new/g` | Replace in visual selection |
| `:s/old/new/` | Replace first on current line |
| `\v` prefix | "Very magic" — most chars are special (closer to regex) |

**Useful patterns:**
```
:%s/\s\+$//          remove trailing whitespace
:%s/\v(\w+)/[\1]/g   wrap every word in brackets
```

---

## Marks

| Key | Action |
|-----|--------|
| `m{a}` | Set mark `a` at cursor |
| `` `{a} `` | Jump to exact position of mark `a` |
| `'{a}` | Jump to line of mark `a` |
| `` `. `` | Jump to last change |
| `` `[ `` / `` `] `` | Start / end of last yank or change |
| `` `< `` / `` `> `` | Start / end of last visual selection |
| `:marks` | List all marks |

Uppercase marks (`mA`–`mZ`) are global — they work across files.

---

## Visual Mode

| Key | Action |
|-----|--------|
| `v` | Character-wise visual |
| `V` | Line-wise visual |
| `Ctrl-V` | Block visual (column select) |
| `o` | Move to other end of selection |
| `gv` | Re-select last visual selection |
| `I` (in block) | Insert text at start of every selected line |
| `A` (in block) | Append text at end of every selected line |

---

## Windows & Splits

| Key | Action |
|-----|--------|
| `:sp` / `:vsp` | Horizontal / vertical split (current file) |
| `:sp file` | Open file in horizontal split |
| `Ctrl-W =` | Equalise all split sizes |
| `Ctrl-W _` | Maximise current split height |
| `Ctrl-W \|` | Maximise current split width |
| `Ctrl-W r` | Rotate splits |

---

## Miscellaneous

| Key | Action |
|-----|--------|
| `.` | Repeat last change |
| `u` / `Ctrl-R` | Undo / redo |
| `J` | Join line below to current |
| `~` | Toggle case of character |
| `Ctrl-A` / `Ctrl-X` | Increment / decrement number under cursor |
| `ga` | Show ASCII / Unicode value of character under cursor |
| `g~iw` | Toggle case of word |
| `:earlier 5m` | Undo to state 5 minutes ago |
| `:later 5m` | Redo to state 5 minutes from now |
| `K` | Look up man page for word under cursor (outside LSP files) |
| `Ctrl-G` | Show current filename and position |

---

## Command Line

| Command | Action |
|---------|--------|
| `:e file` | Open file |
| `:w !sudo tee %` | Save file you opened without sudo |
| `:r !cmd` | Insert output of shell command below cursor |
| `:%!cmd` | Filter entire file through shell command |
| `:g/pattern/d` | Delete all lines matching pattern |
| `:v/pattern/d` | Delete all lines *not* matching (keep matches) |
| `:g/pattern/norm @a` | Run macro `a` on every matching line |
| `Ctrl-R Ctrl-W` | Insert word under cursor into command line |
| `Ctrl-F` | Open command history in editable window |
| `q:` | Same — open command history window |

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

## Snippets by Filetype (Ctrl-E to expand)

| Trigger | Filetype | Expands to |
|---------|----------|------------|
| `file` | proto | Proto3 file header with package + go_package |
| `msg` / `svc` / `rpc` | proto | message / service / rpc definitions |
| `enum` / `oneof` / `map` | proto | enum, oneof, map field |
| `deploy` / `svc` / `cm` | helm | Deployment / Service / ConfigMap template |
| `if` / `range` / `with` | helm | Go template control structures |
| `val` / `tpl` | helm | `.Values.x` reference / `include` call |
| `kust` / `overlay` | yaml (kustomization) | Base or overlay kustomization.yaml |
| `patch` / `cmgen` / `images` | yaml (kustomization) | Patch, ConfigMap generator, image override |
| `play` / `task` / `role` | yaml.ansible | Full playbook / single task / role include |
| `pkg` / `svc` / `template` | yaml.ansible | Package install / service / template task |
| `block` / `loop` / `when` | yaml.ansible | Block+rescue / loop / conditional |
| `golib` / `gobin` / `gotest` | bzl | go_library / go_binary / go_test |
| `proto` / `goproto` | bzl | proto_library / go_proto_library |
| `macro` / `rule` | bzl | Starlark macro / custom rule skeleton |

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
