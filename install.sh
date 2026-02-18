#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Installing dotfiles from $DOTFILES_DIR"

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Function to create symlink with backup
link_config() {
    local src="$1"
    local dest="$2"
    
    if [ -L "$dest" ]; then
        echo "Removing existing symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "Backing up existing config: $dest -> $dest.backup"
        mv "$dest" "$dest.backup"
    fi
    
    echo "Linking: $src -> $dest"
    ln -s "$src" "$dest"
}

# Link nvim config
echo ""
echo "==> Setting up Neovim config..."
link_config "$DOTFILES_DIR/config/nvim" "$CONFIG_DIR/nvim"

# Link opencode config
echo ""
echo "==> Setting up OpenCode config..."
link_config "$DOTFILES_DIR/config/opencode" "$CONFIG_DIR/opencode"

# Link ghostty config
echo ""
echo "==> Setting up Ghostty config..."
link_config "$DOTFILES_DIR/config/ghostty" "$CONFIG_DIR/ghostty"

# Link zed config
echo ""
echo "==> Setting up Zed config..."
link_config "$DOTFILES_DIR/config/zed" "$CONFIG_DIR/zed"

# Install opencode dependencies if bun is available
if command -v bun &> /dev/null; then
    echo ""
    echo "==> Installing OpenCode dependencies with bun..."
    cd "$CONFIG_DIR/opencode"
    bun install
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
