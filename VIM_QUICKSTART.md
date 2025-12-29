# Vim Configuration Quick Start

This guide will get you up and running with the modernized Vim configuration quickly.

## Quick Setup (5 minutes)

### 1. Install Dependencies

```bash
# Install all required tools via Homebrew
brew bundle install

# Or install just the essentials
brew install vim gopls basedpyright ripgrep fzf fd
brew install golangci-lint ruff black shellcheck prettier
brew install --cask font-hack-nerd-font
```

### 2. Apply Dotfiles

```bash
# Apply the new vim configuration
chezmoi apply ~/.vim

# Or if you want to preview first
chezmoi diff ~/.vim
```

### 3. Install Vim Plugins

```bash
# Open vim
vim

# Inside vim, run:
:PlugInstall

# Wait for all plugins to install, then restart vim
```

### 4. (Optional) Configure Claude AI

```bash
# Set your Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Or add to your shell profile for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
```

### 5. Configure Your Terminal Font

For icons to display correctly:

1. Open your terminal preferences (Ghostty, iTerm2, etc.)
2. Set the font to "Hack Nerd Font" or any Nerd Font
3. Restart your terminal

## First Steps in Vim

### Test LSP

```bash
# Open a Go file
vim example.go

# Try these LSP features:
# - Type some code and see autocomplete (appears automatically)
# - Put cursor on a function and press 'K' for documentation
# - Press 'gd' to go to definition
# - Press 'gr' to find references
```

### Test File Navigation

```vim
# Press Ctrl-p to open fuzzy file finder
<C-p>

# Type part of a filename and press Enter

# Or search file contents with ripgrep
,f
```

### Test Git Integration

```bash
# Open any file in a git repo
vim README.md

# See git status
,gs

# Open current file in GitHub/GitLab
,gh
```

### Test AI Assistance

```vim
# Select some code in visual mode
V

# Ask AI for help
,ai what does this code do?

# Or edit code with AI
,ae make this more efficient
```

## Essential Keybindings

Remember: Leader key is `,` (comma)

### Must-Know Shortcuts

```
<C-p>       - Find files (fuzzy search)
,f          - Search in files (ripgrep)
,n          - Toggle file tree

gd          - Go to definition
gr          - Find references
K           - Show documentation

,gs         - Git status
,gh         - Open in GitHub/GitLab

,ai         - Ask AI
,w          - Save file
,q          - Quit
```

## Common Tasks

### Opening a Project

```bash
# Navigate to your project
cd ~/code/myproject

# Open vim in the project root
vim .

# Use Ctrl-p to find files
# Use ,n to see the file tree
# Use ,f to search across files
```

### Editing Go Code

```bash
vim main.go

# LSP will auto-activate
# Auto-complete appears as you type
# Errors show in the gutter
# File auto-formats on save
```

### Working with Git

```vim
# Inside vim:
,gs         - See what's changed
,gd         - See diff
,gc         - Commit
,gh         - Open in browser
```

## Troubleshooting

### "Language server not found"

```bash
# Install the language server
brew install gopls  # for Go
brew install basedpyright  # for Python
brew install marksman  # for Markdown
```

Then restart Vim.

### "Icons look wrong"

Install a Nerd Font:

```bash
brew install --cask font-hack-nerd-font
```

Then set your terminal to use "Hack Nerd Font".

### "Completion not working"

1. Make sure plugins are installed: `:PlugInstall`
2. Check LSP status: `:LspStatus`
3. Restart Vim

### "vim-ai errors"

Check your API key is set:

```bash
echo $ANTHROPIC_API_KEY
```

## Learning More

- Full documentation: `~/.vim/README.md`
- Vim help: `:help` inside Vim
- Plugin help: `:help <plugin-name>` (e.g., `:help vim-lsp`)

## Tips

1. **Use fuzzy finding**: `<C-p>` is your friend for navigating large projects
2. **Use LSP**: `gd` (go to definition) and `gr` (find references) are game-changers
3. **Use git integration**: `,gh` to quickly jump to GitHub/GitLab
4. **Use AI**: `,ai` can explain complex code or suggest improvements
5. **Learn incrementally**: Don't try to memorize all shortcuts at once

## Next Steps

1. Read the full README: `vim ~/.vim/README.md`
2. Customize keybindings: `vim ~/.vim/vimrc`
3. Add your own snippets: Create files in `~/.vim/UltiSnips/`
4. Explore plugins: Each plugin has `:help <plugin-name>` documentation

Enjoy your modern Vim setup!
