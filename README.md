# dotfiles

Personal dotfiles for Neovim, Ghostty, and OpenCode.

## Quick Install

```bash
git clone git@github.com:katsutoo/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

**Prerequisites:** [Neovim](https://neovim.io/) >= 0.9.0, [Bun](https://bun.sh/), [VictorMono Nerd Font](https://www.nerdfonts.com/font-downloads)

## What's Included

### Neovim

[LazyVim](https://www.lazyvim.org/) with custom config:

| Feature | Details |
|---------|---------|
| Dark theme | [aether.nvim](https://github.com/bjarneo/aether.nvim) (custom monotone palette) |
| Light theme | [rose-pine](https://github.com/rose-pine/neovim) dawn |
| Font | VictorMono Nerd Font Mono |
| Completion | nvim-cmp + Copilot (`<C-l>` to accept) |
| AI | 99 plugin |
| File explorer | Neo-tree |

**Keymaps:**

| Key | Action |
|-----|--------|
| `<leader>tt` | Toggle dark/light theme |
| `<leader>9v` | Prompt on visual selection |
| `<leader>9s` | Stop the prompt |

### Ghostty

| Feature | Details |
|---------|---------|
| Font | VictorMono Nerd Font Mono (14) |
| Themes | Aether dark / Rose Pine dawn |
| Opacity | 0.9 |
| Toggle | `~/.config/ghostty/toggle-theme.sh` |

**Keybinds:** `alt+1-5` tabs, `ctrl+shift+o` split, `F11` fullscreen

### OpenCode

- **MCP Servers:** playwright, chrome-devtools, context7
- **Skills:** go, rust, zig astro, solid, svelte

## Updating

```bash
cd ~/dotfiles && git pull
```

Changes take effect immediately (symlinked). Restart nvim for plugin updates.
