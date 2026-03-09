#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Installing dotfiles from $DOTFILES_DIR"

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Return the next available backup path for a config.
next_backup_path() {
    local path="$1"
    local backup_path="${path}.backup"
    local index=1

    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${path}.backup.${index}"
        index=$((index + 1))
    done

    printf '%s\n' "$backup_path"
}

# Create a symlink and preserve any existing config safely.
link_config() {
    local src="$1"
    local dest="$2"
    local backup_path
    local current_target

    if [ ! -e "$src" ]; then
        echo "Error: source config not found: $src" >&2
        exit 1
    fi

    if [ -L "$dest" ]; then
        current_target="$(readlink "$dest")"
        if [ "$current_target" = "$src" ]; then
            echo "Already linked: $dest"
            return
        fi

        echo "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        backup_path="$(next_backup_path "$dest")"
        echo "Backing up existing config: $dest -> $backup_path"
        mv "$dest" "$backup_path"
    fi

    echo "Linking: $src -> $dest"
    ln -s "$src" "$dest"
}

# Link one config directory by name.
setup_config() {
    local name="$1"
    local dir_name="$2"

    echo ""
    echo "==> Setting up $name config..."
    link_config "$DOTFILES_DIR/config/$dir_name" "$CONFIG_DIR/$dir_name"
}

setup_config "Neovim" "nvim"
setup_config "OpenCode" "opencode"
setup_config "Ghostty" "ghostty"
setup_config "Zed" "zed"

# Install opencode dependencies if bun is available
if command -v bun &> /dev/null; then
    echo ""
    echo "==> Installing OpenCode dependencies with bun..."
    (
        cd "$CONFIG_DIR/opencode"
        bun install
    )
else
    echo ""
    echo "Warning: bun not found. Skipping OpenCode dependency installation."
    echo "Install bun and run 'cd ~/.config/opencode && bun install' manually."
fi

echo ""
echo "Done! Dotfiles installed successfully."
echo ""
echo "Neovim: Run 'nvim' to start - Lazy.nvim will auto-install plugins on first launch"
echo "        Then run inside nvim: :Lazy sync, :TSUpdate, :checkhealth"
echo "        Optional: :TSInstall all (or install only specific parsers)"
echo "OpenCode: Configuration ready at ~/.config/opencode"
echo "Ghostty: Restart ghostty for changes to take effect"
echo "         Toggle theme: ~/.config/ghostty/toggle-theme.sh"
echo "Zed: Restart zed for changes to take effect"
