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

### Claude Code
User-level hooks, skills, and settings for Claude Code.

- **Config location**: `claude/`
- **Hooks**: `claude/hooks/elevenlabs-tts/` — ElevenLabs TTS hook that speaks on Stop and PermissionRequest events
- **Skills**:
  - `claude/skills/tts/` — `/tts` skill for on-demand voice messages
  - `claude/skills/ralph/` — `/ralph` skill for supervising headless agent loops across four harnesses (claude, codex, opencode, gh copilot)
- **Settings**: `claude/settings.json` (hooks config), `claude/settings.local.json` (permissions)
- **Guides**: [ElevenLabs TTS Hook (WSL2)](claude/wsl/elevenlabs-tts-hook.md)

**Installation**:
```bash
# Copy hooks
cp -r ~/devvy/von-monorepo/claude/hooks/elevenlabs-tts ~/.claude/hooks/

# Copy skills
mkdir -p ~/.claude/skills/tts ~/.claude/skills/ralph
cp ~/devvy/von-monorepo/claude/skills/tts/SKILL.md ~/.claude/skills/tts/
cp ~/devvy/von-monorepo/claude/skills/ralph/SKILL.md ~/.claude/skills/ralph/

# Copy settings (backs up existing)
[ -f ~/.claude/settings.json ] && cp ~/.claude/settings.json ~/.claude/settings.json.bak
cp ~/devvy/von-monorepo/claude/settings.json ~/.claude/
cp ~/devvy/von-monorepo/claude/settings.local.json ~/.claude/

# Set up API key
cp ~/.claude/hooks/elevenlabs-tts/.env.example ~/.claude/hooks/elevenlabs-tts/.env
# Edit .env with your ELEVENLABS_API_KEY

# Install dependencies
cd ~/.claude/hooks/elevenlabs-tts && bun install
```

### Codex CLI
User-level skills for the OpenAI Codex CLI (`codex`).

- **Config location**: `codex/`
- **Skills**:
  - `codex/skills/ralph/` — `/ralph` skill for supervising headless agent loops (mirrors the Claude Code version, with codex-native invocation rules)

**Installation**:
```bash
mkdir -p ~/.codex/skills/ralph/agents
cp ~/devvy/von-monorepo/codex/skills/ralph/SKILL.md ~/.codex/skills/ralph/
cp ~/devvy/von-monorepo/codex/skills/ralph/agents/openai.yaml ~/.codex/skills/ralph/agents/
```

### OpenCode
User-level skills for the [opencode](https://opencode.ai) CLI.

- **Config location**: `opencode/`
- **Skills**:
  - `opencode/skills/ralph/` — `/ralph` skill for supervising headless agent loops (mirrors the Claude Code version)

**Installation**:
```bash
mkdir -p ~/.config/opencode/skills/ralph
cp ~/devvy/von-monorepo/opencode/skills/ralph/SKILL.md ~/.config/opencode/skills/ralph/
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
