#!/bin/bash

[[ ${OMARCHY_THEME_HOOK_ACTIVE:-} == 1 ]] || exit 0

zellij_config="$HOME/.config/zellij/config.kdl"
if command -v zellij >/dev/null 2>&1 && [[ -f $zellij_config ]]; then
  hex_to_kdl_rgb() {
    local hex=${1#\#}
    printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
  }

  fg=$(hex_to_kdl_rgb "$primary_foreground")
  bg=$(hex_to_kdl_rgb "$primary_background")
  black=$(hex_to_kdl_rgb "$bright_black")
  red=$(hex_to_kdl_rgb "$normal_red")
  green=$(hex_to_kdl_rgb "$normal_green")
  yellow=$(hex_to_kdl_rgb "$normal_yellow")
  blue=$(hex_to_kdl_rgb "$normal_blue")
  magenta=$(hex_to_kdl_rgb "$normal_magenta")
  cyan=$(hex_to_kdl_rgb "$normal_cyan")
  white=$(hex_to_kdl_rgb "$bright_white")
  orange=$(hex_to_kdl_rgb "$bright_yellow")

  zellij_theme_dir="$HOME/.config/zellij/themes"
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
  color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
  [[ $color_scheme == *light* ]] && zellij_action=set-light-theme

  while read -r session status; do
    [[ $status == *EXITED* ]] && continue
    zellij --session "$session" action "$zellij_action" >/dev/null 2>&1 || true
  done < <(zellij list-sessions --no-formatting 2>/dev/null)

  success "Zellij theme updated!"
fi
