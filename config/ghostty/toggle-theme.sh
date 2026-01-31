#!/bin/bash
# Toggle ghostty between dark (aether) and light (rose-pine-dawn) themes

CONFIG_FILE="$HOME/.config/ghostty/config"
DARK_THEME="themes/aether-dark.conf"
LIGHT_THEME="themes/rose-pine-dawn.conf"

if grep -q "$DARK_THEME" "$CONFIG_FILE"; then
    # Switch to light theme
    sed -i "s|config-file = $DARK_THEME|config-file = $LIGHT_THEME|" "$CONFIG_FILE"
    echo "Switched to light theme (rose-pine-dawn)"
else
    # Switch to dark theme
    sed -i "s|config-file = $LIGHT_THEME|config-file = $DARK_THEME|" "$CONFIG_FILE"
    echo "Switched to dark theme (aether)"
fi

echo "Restart ghostty or open a new window for changes to take effect."
