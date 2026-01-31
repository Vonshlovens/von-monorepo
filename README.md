# von-monorepo

Personal configuration files and dotfiles repository.

## Contents

### Ghostty
Terminal emulator configuration with custom sunset theme and background image.

- **Config location**: `ghostty/config`
- **Background image**: `ghostty/background.jpg`
- **Features**:
  - Custom sunset color palette (warm reds, oranges, yellows)
  - Background image with transparency and blur
  - SF Mono font with custom sizing
  - Custom keybindings for tab and window management

**Installation**:
```bash
# Symlink the config
ln -sf ~/devvy/von-monorepo/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config

# Reload with Cmd+Shift+, in Ghostty
```

### Neovim (LazyVim)
Neovim configuration using LazyVim framework.

- **Config location**: `nvim/config/`
- **Plugin manager**: lazy.nvim
- **Features**:
  - LazyVim base configuration
  - Custom sunset theme plugin
  - Custom keymaps and autocmds

**Installation**:
```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup

# Symlink the config
ln -sf ~/devvy/von-monorepo/nvim/config ~/.config/nvim

# Launch nvim - plugins will install automatically
nvim
```

### Tmux
Terminal multiplexer configuration.

- **Config location**: `tmux/tmux.conf`

**Installation**:
```bash
# Symlink the config
ln -sf ~/devvy/von-monorepo/tmux/tmux.conf ~/.tmux.conf

# Reload tmux config
tmux source-file ~/.tmux.conf
```

## Setup

Clone the repository:
```bash
git clone https://github.com/vonshlovens/von-monorepo.git ~/devvy/von-monorepo
```

Then follow the installation instructions for each tool above.

## License

Personal configuration files - use at your own discretion.
