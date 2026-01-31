# dotfiles

Personal dotfiles for Neovim and OpenCode configurations.

## What's Included

### Neovim (`config/nvim`)

Based on [LazyVim](https://www.lazyvim.org/) with custom configurations:

- **Colorscheme:** [aether.nvim](https://github.com/bjarneo/aether.nvim) with custom dark monotone palette
- **Light theme:** [rose-pine](https://github.com/rose-pine/neovim) (dawn variant)
- **Font:** VictorMono Nerd Font Mono (set in terminal or GUI Neovim)
- **Transparent backgrounds** for all UI elements (dark theme)
- **Theme toggle:** `<leader>tt` to switch between dark/light
- **Theme hot-reload** for quick colorscheme switching
- **Copilot integration** with `<C-l>` to accept suggestions
- **99 plugin** (ThePrimeagen) with Claude Opus 4.5 for AI assistance
- **nvim-cmp** for completion (instead of blink.cmp)
- **Neo-tree** for file exploration

**Available Themes:** aether, bamboo, catppuccin, everforest, flexoki, gruvbox, kanagawa, matteblack, monokai-pro, nord, rose-pine, tokyonight

**Theme Keymaps:**
- `<leader>tt` - Toggle dark (aether) / light (rose-pine dawn) theme

**99 Keymaps:**
- `<leader>9f` - Fill in function with AI
- `<leader>9v` - AI operate on visual selection
- `<leader>9p` - AI operate on visual selection with prompt
- `<leader>9s` - Stop AI requests

### OpenCode (`config/opencode`)

- **MCP Servers:** playwright, chrome-devtools, context7
- **Custom Skills:** postgresql-sql, astro-frontend, solid-frontend, svelte-frontend, gleam-backend, zig-backend, rust-backend, go-backend, frontend-design

## Installation

### Prerequisites

- [Neovim](https://neovim.io/) >= 0.9.0
- [Git](https://git-scm.com/)
- [Bun](https://bun.sh/) (for OpenCode dependencies)
- [VictorMono Nerd Font](https://www.nerdfonts.com/font-downloads) - set this in your terminal emulator

### Quick Install

```bash
# Clone the repository
git clone git@github.com:katsutoo/dotfiles.git ~/dotfiles

# Run the install script
cd ~/dotfiles
./install.sh
```

The install script will:
1. Backup any existing configs (to `~/.config/nvim.backup`, etc.)
2. Create symlinks from `~/.config/` to this repo
3. Install OpenCode dependencies with bun (if available)

### Manual Install

If you prefer to install manually:

```bash
# Clone the repo
git clone git@github.com:katsutoo/dotfiles.git ~/dotfiles

# Create symlinks
ln -s ~/dotfiles/config/nvim ~/.config/nvim
ln -s ~/dotfiles/config/opencode ~/.config/opencode

# Install OpenCode dependencies
cd ~/.config/opencode && bun install
```

### First Run

**Neovim:** On first launch, Lazy.nvim will automatically install all plugins. Just run:

```bash
nvim
```

Wait for the installation to complete, then restart Neovim.

## Updating

To pull the latest changes:

```bash
cd ~/dotfiles
git pull
```

Since configs are symlinked, changes take effect immediately (restart nvim for plugin changes).

## Structure

```
dotfiles/
├── config/
│   ├── nvim/           # Neovim configuration
│   │   ├── init.lua
│   │   ├── lua/
│   │   │   ├── config/     # Core config (options, keymaps, autocmds)
│   │   │   └── plugins/    # Plugin configurations
│   │   └── plugin/
│   │       └── after/      # Post-load configs (transparency)
│   └── opencode/       # OpenCode configuration
│       ├── opencode.json   # Main config
│       └── skills/         # Custom AI skills
├── install.sh          # Installation script
└── README.md
```

## Customization

### Changing the Colorscheme

Edit `config/nvim/lua/plugins/theme.lua`:

```lua
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",  -- Change to any available theme
    },
  },
}
```

### Disabling Transparency

Remove or comment out the contents of `config/nvim/plugin/after/transparency.lua`.

## License

MIT
