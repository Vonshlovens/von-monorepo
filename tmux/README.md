# Tmux Setup

This configuration uses:

- [Catppuccin for tmux](https://github.com/catppuccin/tmux) `v2.3.0`, using the Mocha flavor
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
- [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) for the CPU and RAM status modules

## Requirements

- tmux 3.2 or newer
- Git
- A terminal configured to use a [Nerd Font](https://www.nerdfonts.com/font-downloads)

The Catppuccin theme works without a Nerd Font, but its status icons will be
missing or replaced by boxes. `JetBrainsMono Nerd Font` is a suitable choice.
The repository's Ghostty config currently uses plain `SF Mono`, so change its
`font-family` setting if using that config with this tmux status line.

## Install

Clone this repository, then symlink its tmux configuration:

```bash
ln -sf ~/devvy/von-monorepo/tmux/tmux.conf ~/.tmux.conf
```

Install TPM:

```bash
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Install the Catppuccin theme manually. The manual installation avoids the
plugin-name conflict described by the Catppuccin project:

```bash
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone --branch v2.3.0 --depth 1 \
  https://github.com/catppuccin/tmux.git \
  ~/.config/tmux/plugins/catppuccin/tmux
```

Start tmux:

```bash
tmux
```

Press `Ctrl-a`, then `Shift-i` to install `tmux-sensible` and `tmux-cpu`
through TPM. The configured prefix is `Ctrl-a`, not tmux's default `Ctrl-b`.

Reload an existing tmux server after changing the configuration:

```bash
tmux source-file ~/.tmux.conf
```

## Updates

Update TPM-managed plugins with `Ctrl-a`, then `Shift-u`.

Catppuccin is pinned to `v2.3.0`. To reinstall that exact version:

```bash
git -C ~/.config/tmux/plugins/catppuccin/tmux fetch --tags
git -C ~/.config/tmux/plugins/catppuccin/tmux checkout v2.3.0
```

## Troubleshooting

Check that the expected files exist:

```bash
test -x ~/.tmux/plugins/tpm/tpm
test -x ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
test -d ~/.tmux/plugins/tmux-cpu
```

Check the tmux version:

```bash
tmux -V
```

If colors or options remain stale after reloading, stop all tmux sessions and
start tmux again. If icons are incorrect but colors work, configure the
terminal application itself to use a Nerd Font.
