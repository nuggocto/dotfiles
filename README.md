# Personal Config

Personal Linux config for [Omarchy](https://omarchy.org) ;D

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
into place. It's safe to re-run — it only touches what isn't already linked.

Afterwards:
- Edit `hypr/monitors.conf` for this machine's displays (`hyprctl monitors`).
- Install the Nerd Fonts (VictorMono / JetBrainsMono) if missing.
- Log out/in or `hyprctl reload`, and restart waybar/terminals.

## What's tracked

| Config | What it is |
| --- | --- |
| `hypr` | Hyprland overrides (bindings, looknfeel, monitors, idle/lock, etc.) |
| `waybar` | Bar config, style, and the japanese-clock scripts |
| `fastfetch` | fastfetch config + custom logo |
| `fish` | Shell config (`fish_variables` is gitignored) |
| `zellij` | Zellij keybinds / theme |
| `btop` | btop config (theme symlink is per-machine, gitignored) |
| `ghostty` | Primary terminal config |
| `nvim` | Neovim (LazyVim) config, plugin specs, lockfile |
| `zed` | Zed settings + keymap |
| `opencode` | Opencode config, TUI settings, skills |

## Notes

- This is config only; system packages are installed separately by Omarchy.
