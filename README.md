# Config

Personal Linux config for [Omarchy](https://omarchy.org) (̿▀̿ ̿Ĺ̯̿̿▀̿ ̿)̄

These are my customizations *on top of* a stock Omarchy install. Each tracked
config is symlinked from this repo into `~/.config`, so any style tweak I make
afterwards lands straight back in git.

## New machine setup

```sh
# 1. Install Omarchy as usual, then:
git clone git@github.com:nuggocto/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

`install.sh` figures out its own location, so you can clone the repo anywhere.
`~/.dotfiles` is just the suggested spot. The symlinks always point back to
wherever the repo lives. It backs up anything already at each destination (into
`~/.config/dotfiles-backup-<timestamp>/`), then symlinks every tracked config
into place. It is safe to re-run. It leaves correct links alone and removes
obsolete skill links only when they point back into this repository.

The installer also exposes the shared language and workflow skills from
`opencode/skills` through `~/.agents/skills`.

Claude Code settings are linked separately into `~/.claude/settings.json`.
The installer requires `jq` and merges the public MCP endpoints from
`claude/mcp.json` into the machine-local `~/.claude.json`, preserving unrelated
servers and account/project state. Run `./install.sh --claude-only` to apply just
this configuration. See [Claude setup and authentication](claude/README.md).

Afterwards:
- `hypr/monitors.lua` currently targets a BenQ EX271UZ on `HDMI-A-1` at
  3840x2160@120 with 1.6 scale. Edit it for another display (`hyprctl monitors`).
- Install the Nerd Fonts (VictorMono / JetBrainsMono) if missing.
- Run `omarchy theme set solitude` to generate and distribute app themes.
- Log out/in or run `hyprctl reload`. Restart the Omarchy Shell and terminals
  with `omarchy restart shell` and `omarchy restart terminal` if needed.

## What's tracked

| Config | What it is |
| --- | --- |
| `hypr` | Hyprland Lua overrides, night light, and screen-sharing portal config |
| `fastfetch` | fastfetch config + custom logo |
| `fish` | Shell config (`fish_variables` is gitignored) |
| `starship.toml` | Prompt layout and semantic ANSI colors |
| `git`, `lazygit` | Git behavior, diff colors, and Lazygit theme |
| `btop` | btop config (theme symlink is per-machine, gitignored) |
| `ghostty` | Primary terminal config |
| `nvim` | Neovim (LazyVim) config, plugin specs, lockfile |
| `zed` | Zed settings + keymap |
| `opencode` | OpenCode config, TUI settings, and shared agent skills |
| `claude` | Claude Code settings and public MCP endpoints; credentials and runtime state stay local |
| `omarchy` | Omarchy Shell bar/idle config, shell text size, Navbar Cat setup, Solitude patch, and theme hooks/templates |

## Notes

- This is config only; system packages are installed separately by Omarchy.
- Omarchy's generated `current/` directory is intentionally not tracked. The
  installer links only custom hooks/templates and applies `solitude.patch` to
  a clone of the upstream Solitude theme.
