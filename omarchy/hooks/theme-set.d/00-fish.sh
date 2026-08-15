#!/bin/bash

command -v fish >/dev/null 2>&1 || exit 0

theme_dir="$HOME/.local/state/omarchy/current/theme"
colors_file="$theme_dir/colors.toml"
output_file="$theme_dir/colors.fish"
[[ -f $colors_file ]] || exit 0

color() {
  omarchy-theme-color --file "$colors_file" "$1"
}

cat >"$output_file" <<EOF
set -U background '$(color background)'
set -U foreground '$(color foreground)'
set -U cursor '$(color foreground)'
set -U color0 '$(color background)'
set -U color1 '$(color red)'
set -U color2 '$(color green)'
set -U color3 '$(color yellow)'
set -U color4 '$(color blue)'
set -U color5 '$(color magenta)'
set -U color6 '$(color cyan)'
set -U color7 '$(color foreground)'
set -U color8 '$(color muted)'
set -U color9 '$(color bright_red)'
set -U color10 '$(color bright_green)'
set -U color11 '$(color bright_yellow)'
set -U color12 '$(color bright_blue)'
set -U color13 '$(color bright_magenta)'
set -U color14 '$(color bright_cyan)'
set -U color15 '$(color bright_foreground)'

set -U fish_color_normal normal
set -U fish_color_command green
set -U fish_color_param cyan
set -U fish_color_quote yellow
set -U fish_color_redirection blue
set -U fish_color_end magenta
set -U fish_color_error red --bold
set -U fish_color_comment brblack --italics
set -U fish_color_operator yellow
set -U fish_color_escape brcyan
set -U fish_color_autosuggestion brblack
set -U fish_color_cwd blue
set -U fish_color_cwd_root red
set -U fish_color_valid_path --underline
set -U fish_pager_color_completion normal
set -U fish_pager_color_description yellow
set -U fish_pager_color_prefix cyan --bold
set -U fish_pager_color_progress brwhite --background=blue
set -U fish_pager_color_selected_background --background=brblack
set -U fish_color_history_current --bold
EOF

fish -c "source '$output_file'"
