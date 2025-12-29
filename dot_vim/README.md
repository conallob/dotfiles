# Modern Vim Configuration

A comprehensive, modern Vim configuration optimized for Go and Python development, with full LSP support, AI assistance, and GitHub/GitLab integration.

## Features

### Core Capabilities
- **LSP Support**: Full Language Server Protocol integration with vim-lsp
- **Auto-completion**: Async completion with asyncomplete.vim
- **AI Assistance**: Claude and Windsurf AI integration for code assistance
- **Git Integration**: Full GitHub and GitLab support with fugitive
- **Fuzzy Finding**: Fast file navigation with fzf
- **Linting & Formatting**: Comprehensive linting with ALE and auto-formatting on save

### Language Support
- **Go**: gopls LSP, vim-go tooling, syntax highlighting
- **Python**: basedpyright LSP, ruff linting, black formatting
- **Markdown**: marksman LSP, enhanced syntax, prettierformatting
- **LaTeX**: texlab LSP, vimtex integration
- **HTML**: html-languageserver, prettier formatting
- **Protobuf**: Syntax highlighting and indentation
- **GraphViz DOT**: Syntax support
- **d2lang**: Via vim-polyglot
- **YAML**: LSP support, yamllint, prettier formatting (great for CI configs)

## Installation

### 1. Install Dependencies

Using Homebrew (macOS):

```bash
# Apply your dotfiles (which includes the updated Brewfile)
chezmoi apply

# Or install Homebrew packages manually
brew bundle install
```

This will install:
- Vim with modern features
- Language servers (gopls, basedpyright, marksman, etc.)
- Linters and formatters (golangci-lint, ruff, black, prettier, etc.)
- Search tools (ripgrep, fzf, fd)
- Nerd Font for icons

### 2. Install Vim Plugins

Open Vim and run:

```vim
:PlugInstall
```

This will install all configured plugins via vim-plug.

### 3. Install Language Servers

The vim-lsp-settings plugin will automatically offer to install language servers when you open supported file types. Alternatively, manually install:

```vim
:LspInstallServer
```

### 4. Configure Claude AI (Optional)

To use Claude AI integration via vim-ai, set your Anthropic API key:

```bash
# Add to your shell profile or use 1Password integration
export ANTHROPIC_API_KEY="your-api-key-here"
```

Or configure it to read from 1Password in your shell.d environment files.

## Key Bindings

### Leader Key
The leader key is set to `,` (comma)

### LSP Features

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `gs` | Document symbols |
| `gS` | Workspace symbols |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions |
| `[g` | Previous diagnostic |
| `]g` | Next diagnostic |

### File Navigation

| Key | Action |
|-----|--------|
| `<C-p>` | Fuzzy find files |
| `<leader>b` | List buffers |
| `<leader>f` | Ripgrep search |
| `<leader>t` | Search tags |
| `<leader>m` | List marks |
| `<leader>h` | File history |
| `<leader>n` | Toggle NERDTree |
| `<leader>nf` | Find current file in NERDTree |

### Git Operations

| Key | Action |
|-----|--------|
| `<leader>gs` | Git status |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gl` | Git pull |
| `<leader>gd` | Git diff split |
| `<leader>gb` | Git blame |
| `<leader>gh` | Open in GitHub/GitLab (GBrowse) |
| `[h` | Previous git hunk |
| `]h` | Next git hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hu` | Undo hunk |
| `<leader>hp` | Preview hunk |

### AI Assistance

| Key | Action |
|-----|--------|
| `<leader>ai` | Ask AI (normal/visual mode) |
| `<leader>ae` | AI edit (normal/visual mode) |
| `<leader>ac` | Open AI chat |

### Go-Specific (when editing .go files)

| Key | Action |
|-----|--------|
| `<leader>gb` | Go build |
| `<leader>gr` | Go run |
| `<leader>gt` | Go test |
| `<leader>gc` | Go coverage toggle |
| `<leader>ga` | Go alternate (switch test/impl) |
| `<leader>gd` | Go doc |
| `<leader>gi` | Go implement interface |
| `<leader>gf` | Go fill struct |

### Completion

| Key | Action |
|-----|--------|
| `<Tab>` | Next completion item |
| `<S-Tab>` | Previous completion item |
| `<CR>` | Accept completion |
| `<C-j>` | Expand/jump forward snippet |
| `<C-k>` | Jump backward snippet |

### Window Navigation

| Key | Action |
|-----|--------|
| `<C-h>` | Move to left split |
| `<C-j>` | Move to split below |
| `<C-k>` | Move to split above |
| `<C-l>` | Move to right split |

### Buffer Management

| Key | Action |
|-----|--------|
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |
| `<leader>bd` | Delete buffer |

### Tab Management

| Key | Action |
|-----|--------|
| `<leader>tn` | New tab |
| `<leader>tc` | Close tab |
| `<leader>th` | Previous tab |
| `<leader>tl` | Next tab |

### Spell Checking

| Key | Action |
|-----|--------|
| `<leader>ss` | Toggle spell check |
| `<leader>sn` | Next misspelled word |
| `<leader>sp` | Previous misspelled word |
| `<leader>sa` | Add word to dictionary |
| `<leader>s?` | Suggest corrections |

### Other Useful Bindings

| Key | Action |
|-----|--------|
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>x` | Save and quit |
| `<leader>/` | Clear search highlighting |
| `<leader>ev` | Edit vimrc in vertical split |
| `<leader>sv` | Source vimrc (reload config) |
| `<leader>=` | Format entire file |
| `<F2>` | Toggle paste mode |

## GitHub/GitLab CI Integration

### Opening Files in Browser

Use `:GBrowse` to open the current file or selection in GitHub or GitLab:

```vim
" Open current file in browser
:GBrowse

" Open current line in browser
:GBrowse

" Open visual selection in browser (in visual mode)
:'<,'>GBrowse

" Or use the keybinding
<leader>gh
```

This works automatically for both GitHub (via vim-rhubarb) and GitLab (via fugitive-gitlab).

### Configuring GitLab Domains

If you use self-hosted GitLab, add your domain to the vimrc:

```vim
let g:fugitive_gitlab_domains = ['https://gitlab.com', 'https://gitlab.yourcompany.com']
```

### Viewing CI Status

While the config doesn't include dedicated CI status plugins (to keep it lightweight), you can:

1. Use `:GBrowse` to quickly jump to the GitHub/GitLab page to check CI
2. Use terminal integration with `gh` CLI or `glab` CLI
3. View `.github/workflows/` or `.gitlab-ci.yml` files with YAML LSP support

## Auto-Formatting

Files are automatically formatted on save according to the configured formatters:

- **Go**: gofmt, goimports
- **Python**: black, isort
- **JavaScript/TypeScript**: prettier
- **JSON/YAML**: prettier
- **Markdown**: prettier
- **HTML**: prettier

To disable auto-format on save for a specific file, add to the top of the file:

```vim
" vim: ale_fix_on_save=0
```

## Linting

ALE provides real-time linting for:

- **Go**: golangci-lint, gofmt
- **Python**: ruff, mypy
- **Shell scripts**: shellcheck
- **Markdown**: markdownlint
- **YAML**: yamllint
- **Dockerfile**: hadolint

Lint errors and warnings appear:
- In the sign column (left gutter)
- In the status line (via airline)
- As virtual text next to the problematic code
- In the location list (`:lopen`)

## Color Schemes

The configuration includes two modern color schemes:

- **Gruvbox** (default): Retro groove color scheme
- **Nord**: Arctic, north-bluish color palette

To switch to Nord, edit the vimrc:

```vim
colorscheme nord
let g:airline_theme = 'nord'
```

## File Templates

New files automatically use templates from `~/.vim/templates/`:

- `py.tpl` - Python files
- `sh.tpl` - Shell scripts

Add more templates by creating `<extension>.tpl` files.

## Troubleshooting

### LSP Not Working

1. Check if the language server is installed:
   ```vim
   :LspStatus
   ```

2. Install the server manually:
   ```vim
   :LspInstallServer
   ```

3. Check LSP logs:
   ```vim
   :LspLog
   ```

### Completion Not Working

1. Ensure asyncomplete is loaded:
   ```vim
   :echo asyncomplete#get_sources()
   ```

2. Check if LSP is providing completions:
   ```vim
   :LspStatus
   ```

### Icons Not Displaying

Install a Nerd Font:

```bash
brew install font-hack-nerd-font
```

Then configure your terminal to use "Hack Nerd Font".

### vim-ai Not Working

1. Check if the API key is set:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. Verify the vim-ai configuration in vimrc:
   ```vim
   :echo g:vim_ai_chat
   ```

3. Check for errors:
   ```vim
   :messages
   ```

## Customization

### Adding More Language Servers

Edit the vimrc to register additional LSP servers. Example for Rust:

```vim
if executable('rust-analyzer')
  au User lsp_setup call lsp#register_server({
    \ 'name': 'rust-analyzer',
    \ 'cmd': {server_info->['rust-analyzer']},
    \ 'whitelist': ['rust'],
    \ })
endif
```

### Changing Leader Key

Edit the vimrc:

```vim
let mapleader = " "  " Use space as leader instead of comma
```

### Disabling Auto-Format on Save

Edit the vimrc:

```vim
let g:ale_fix_on_save = 0
```

Or disable for specific filetypes:

```vim
let g:ale_fix_on_save = 1
let g:ale_fix_on_save_ignore = ['python', 'go']
```

## Advanced Features

### Code Folding

The configuration disables LSP-based folding by default, but you can enable it:

```vim
let g:lsp_fold_enabled = 1
```

Then use standard Vim folding commands:
- `zc` - Close fold
- `zo` - Open fold
- `za` - Toggle fold
- `zR` - Open all folds
- `zM` - Close all folds

### Semantic Highlighting

LSP semantic highlighting is enabled by default, providing more accurate syntax highlighting based on the language server's understanding of your code.

### Virtual Text

Diagnostic messages appear as virtual text next to problematic lines. To disable:

```vim
let g:lsp_diagnostics_virtual_text_enabled = 0
```

## Plugin Documentation

For detailed documentation on any plugin, use Vim's help system:

```vim
:help vim-lsp
:help ale
:help fugitive
:help fzf-vim
:help vim-go
```

## Performance Tips

1. **Large Files**: Syntax highlighting is limited to the first 500 columns for performance
2. **Lazy Loading**: Many plugins are loaded only for specific filetypes
3. **Async Operations**: LSP and completion work asynchronously to avoid blocking

## Resources

- [vim-lsp documentation](https://github.com/prabirshrestha/vim-lsp)
- [ALE documentation](https://github.com/dense-analysis/ale)
- [vim-go tutorial](https://github.com/fatih/vim-go/wiki/Tutorial)
- [vim-ai usage](https://github.com/madox2/vim-ai)
- [fugitive screencast](http://vimcasts.org/episodes/fugitive-vim---a-complement-to-command-line-git/)

## Contributing

This is a personal dotfiles configuration. If you find it useful, feel free to fork and adapt to your needs!
