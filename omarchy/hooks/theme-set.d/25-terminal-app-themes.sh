#!/bin/bash

theme_dir="$HOME/.local/state/omarchy/current/theme"
colors_file="$theme_dir/colors.toml"
[[ -f $colors_file ]] || exit 0

mode=$(omarchy-theme-color --file "$colors_file" mode)
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
opencode_theme_dir="$config_home/opencode/themes"
opencode_source_theme="$opencode_theme_dir/solitude.json"
opencode_active_theme="$opencode_theme_dir/omarchy-current.json"
zed_settings="$config_home/zed/settings.json"

# Run again after custom hooks so system-aware apps see the final mode.
if command -v omarchy-theme-set-gnome >/dev/null 2>&1; then
  omarchy-theme-set-gnome
fi

# Zed can retain the previous Linux portal mode after receiving the live change.
# Reloading unchanged settings makes it resolve system mode again without a restart.
if [[ -f $zed_settings ]] && pgrep -x zed-editor >/dev/null; then
  sleep 0.5
  touch "$zed_settings"
fi

# Duplicate the active variant into both branches so an OpenCode mode lock cannot
# prevent Omarchy theme changes from taking effect.
if command -v jq >/dev/null 2>&1 && [[ -f $opencode_source_theme ]]; then
  tmp_theme=$(mktemp "$opencode_active_theme.XXXXXX")
  if jq --arg mode "$mode" '
    walk(
      if type == "object" and has("dark") and has("light") then
        .[$mode] as $color | { dark: $color, light: $color }
      else
        .
      end
    )
  ' "$opencode_source_theme" >"$tmp_theme"; then
    mv "$tmp_theme" "$opencode_active_theme"
  else
    rm -f "$tmp_theme"
  fi
fi

if [[ ${OMARCHY_THEME_SKIP_OPENCODE_RELOAD:-} != 1 ]]; then
  omarchy-restart-opencode
fi

zellij_config="$config_home/zellij/config.kdl"
if command -v zellij >/dev/null 2>&1 && [[ -f $zellij_config ]]; then
  hex_to_kdl_rgb() {
    local hex=${1#\#}
    printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
  }

  fg=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" foreground)")
  bg=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" background)")
  black=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" muted)")
  red=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" red)")
  green=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" green)")
  yellow=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" yellow)")
  blue=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" blue)")
  magenta=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" magenta)")
  cyan=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" cyan)")
  white=$(hex_to_kdl_rgb "$(omarchy-theme-color --file "$colors_file" bright_foreground)")
  orange=$yellow

  zellij_theme_dir="$config_home/zellij/themes"
  mkdir -p "$zellij_theme_dir"
  cat >"$zellij_theme_dir/omarchy-active.kdl" <<EOF
themes {
  omarchy-active {
    fg $fg
    bg $bg
    black $black
    red $red
    green $green
    yellow $yellow
    blue $blue
    magenta $magenta
    cyan $cyan
    white $white
    orange $orange
  }
}
EOF

  zellij_action=set-dark-theme
  [[ $mode == light ]] && zellij_action=set-light-theme
  while read -r session status; do
    [[ $status == *EXITED* ]] && continue
    zellij --session "$session" action "$zellij_action" >/dev/null 2>&1 || true
  done < <(zellij list-sessions --no-formatting 2>/dev/null)
fi
