#!/usr/bin/env bash
#
# Bootstrap these dotfiles on a fresh machine (designed for Omarchy).
#
# It symlinks each tracked config from this repo into ~/.config so that any
# future edits land straight back in git. Anything already present at the
# destination is moved into a timestamped backup folder first, so the script
# is safe and reversible. Re-running it is idempotent.
#
# Usage (clone anywhere — the script resolves its own location):
#   git clone git@github.com:nuggocto/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/install.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$CONFIG_DIR/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Repo entries that map 1:1 to ~/.config/<name>.
CONFIGS=(
  # Editors / terminals / tools
  ghostty nvim zed opencode zellij btop fastfetch
  # Omarchy desktop layer (your overrides on top of Omarchy defaults)
  hypr waybar fish
)

link() {
  local name="$1"
  local src="$REPO_DIR/$name"
  local dest="$CONFIG_DIR/$name"

  if [ ! -e "$src" ]; then
    printf '  skip  %-12s (not in repo)\n' "$name"
    return
  fi

  # Already correctly linked? Leave it.
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    printf '  ok    %-12s (already linked)\n' "$name"
    return
  fi

  # Back up whatever is currently there (real dir, file, or stale symlink).
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    printf '  back  %-12s -> %s/\n' "$name" "$BACKUP_DIR"
  fi

  ln -s "$src" "$dest"
  printf '  link  %-12s -> %s\n' "$name" "$src"
}

echo "Dotfiles : $REPO_DIR"
echo "Target   : $CONFIG_DIR"
echo
mkdir -p "$CONFIG_DIR"
for c in "${CONFIGS[@]}"; do link "$c"; done
echo

if [ -d "$BACKUP_DIR" ]; then
  echo "Replaced files were backed up to: $BACKUP_DIR"
fi

cat <<'NOTE'

Done. A couple of per-machine things to check by hand:
  - hypr/monitors.conf  : display layout/resolution/scale is machine-specific.
                          Run `hyprctl monitors` and edit it for this machine.
  - Fonts               : install your Nerd Fonts (VictorMono / JetBrainsMono)
                          if they're missing.
  - Reload              : log out/in (or `hyprctl reload`) to apply Hyprland,
                          and restart waybar/terminals to pick up changes.
NOTE
