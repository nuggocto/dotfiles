# dotfiles

Personal dotfiles for Neovim, Ghostty, Zed, and OpenCode.

## Quick Install

```bash
git clone git@github.com:nuggocto/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

**Prerequisites:** [Neovim](https://neovim.io/) >= 0.9.0 and [VictorMono Nerd Font](https://www.nerdfonts.com/font-downloads). [Bun](https://bun.sh/) is optional and only needed to install OpenCode dependencies automatically.

## What's Included

### Neovim

[LazyVim](https://www.lazyvim.org/) with custom config:

| Feature | Details |
|---------|---------|
| Dark theme | [aether.nvim](https://github.com/bjarneo/aether.nvim) (custom monotone palette) |
| Light theme | [rose-pine](https://github.com/rose-pine/neovim) dawn |
| Font | VictorMono Nerd Font Mono |
| AI | 99 plugin |
| File explorer | Neo-tree |

**Keymaps:**

| Key | Action |
|-----|--------|
| `<leader>tt` | Toggle dark/light theme |

### Ghostty

| Feature | Details |
|---------|---------|
| Font | VictorMono Nerd Font Mono (14) |
| Themes | Aether dark / Rose Pine dawn |
| Opacity | 0.9 |
| Toggle | `~/.config/ghostty/toggle-theme.sh` |

**Keybinds:** `alt+1-5` tabs, `ctrl+shift+o` split, `F11` fullscreen, `Ctrl+Shift+T` new tab, `Ctrl+Shift+P` open command palette

### Zed

| Feature | Details |
|---------|---------|
| Theme | Rosé Pine Dawn (light) / Gruvbox Material Dark Mix (dark) |
| Font | VictorMono Nerd Font Mono |
| Vim mode | Enabled |

### OpenCode

- **MCP Servers:** playwright, chrome-devtools, context7
- **Skills:** go, rust, zig, frontend-design, postgres, mysql, neki, railway, cloudflare, wrangler, tiger_style, web_perf

## Post-Install (Neovim)

After running the installer on a fresh machine:

1. Open `nvim` once and wait for Lazy.nvim to finish installing plugins.
2. Run `:Lazy sync`.
3. Run `:TSUpdate`.
4. If needed, run `:TSInstall all` (or install only specific parsers).
5. Run `:checkhealth` and fix any missing dependencies reported.

## Updating

```bash
cd ~/dotfiles && git pull
```

Changes take effect immediately (symlinked). Restart nvim for plugin updates.
