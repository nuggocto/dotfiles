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

`install.sh` figures out its own location, so you can clone the repo anywhere
(`~/.dotfiles` is just the suggested spot) — the symlinks always point back to
wherever it lives. It backs up anything already at each destination (into
`~/.config/dotfiles-backup-<timestamp>/`), then symlinks every tracked config
into place. It is safe to re-run. It leaves correct links alone and removes
obsolete skill links only when they point back into this repository.

The installer also exposes the shared language and workflow skills from
`opencode/skills` to Codex, Kimi CLI, and Grok CLI. Kimi and Grok use
the shared `~/.agents/skills` links; each tool reads the same tracked files
without copied skill bundles drifting apart.

Afterwards:
- Edit `hypr/monitors.lua` for this machine's displays (`hyprctl monitors`).
- Install the Nerd Fonts (VictorMono / JetBrainsMono) if missing.
- Run `omarchy theme set solitude` to generate and distribute app themes.
- Log out/in or `hyprctl reload`, and restart waybar/terminals.

## What's tracked

| Config | What it is |
| --- | --- |
| `hypr` | Hyprland overrides (bindings, looknfeel, monitors, idle/lock, etc.) |
| `waybar` | Bar config, style, and custom Chinese clock |
| `fastfetch` | fastfetch config + custom logo |
| `fish` | Shell config (`fish_variables` is gitignored) |
| `starship.toml` | Prompt layout and semantic ANSI colors |
| `git`, `lazygit` | Git behavior, diff colors, and Lazygit theme |
| `zellij` | Zellij keybinds and generated Omarchy theme integration |
| `btop` | btop config (theme symlink is per-machine, gitignored) |
| `ghostty` | Primary terminal config |
| `nvim` | Neovim (LazyVim) config, plugin specs, lockfile |
| `zed` | Zed settings + keymap |
| `opencode` | OpenCode config, TUI settings, and canonical agent skills shared with Codex, Kimi CLI, and Grok CLI |
| `omarchy` | Solitude patch plus selective theme hooks/templates |

## Notes

- This is config only; system packages are installed separately by Omarchy.
- Omarchy's generated `current/` directory is intentionally not tracked. The
  installer links only custom hooks/templates and applies `solitude.patch` to
  a clone of the upstream Solitude theme.
