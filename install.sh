#!/usr/bin/env bash
#
# Bootstrap these dotfiles on a fresh machine (designed for Omarchy).
#
# It symlinks each tracked config from this repo into ~/.config and selected
# agent skills into each tool's discovery directory, so future edits land
# straight back in git. Anything already present at a destination is moved into
# a timestamped backup folder first. Re-running it is idempotent.
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
  ghostty nvim zed opencode zellij btop fastfetch git lazygit
  # Omarchy desktop layer (your overrides on top of Omarchy defaults)
  hypr waybar fish
)

# Standalone files that live directly under ~/.config.
CONFIG_FILES=(
  starship.toml
)

# Selective Omarchy files. Never link the whole directory because current/
# contains generated runtime state.
OMARCHY_FILES=(
  omarchy/hooks/theme-set.d/00-fish.sh
  omarchy/hooks/theme-set.d/25-terminal-app-themes.sh
  omarchy/themed/ghostty.conf.tpl
)

# Canonical skills live under opencode/skills. OpenCode reads them through its
# config link; these links expose the shared language and workflow skills to the
# other supported agents without flooding their discovery budgets.
AGENT_SKILLS=(
  benchmark
  choose-data-structures
  fastapi
  gleam
  go
  postgres
  python
  qa
  rust
  security
  test-quality
  tiger-style
  unslop
  use-railway
  zig
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

link_file() {
  local relative_path="$1"
  local src="$REPO_DIR/$relative_path"
  local dest="$CONFIG_DIR/$relative_path"
  local backup="$BACKUP_DIR/$relative_path"

  if [ ! -f "$src" ]; then
    printf '  skip  %-44s (not in repo)\n' "$relative_path"
    return
  fi

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    printf '  ok    %-44s (already linked)\n' "$relative_path"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$(dirname "$backup")"
    mv "$dest" "$backup"
    printf '  back  %-44s -> %s\n' "$relative_path" "$backup"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  printf '  link  %-44s -> %s\n' "$relative_path" "$src"
}

link_external_file() {
  local relative_path="$1"
  local dest="$2"
  local backup_relative="$3"
  local src="$REPO_DIR/$relative_path"
  local backup="$BACKUP_DIR/$backup_relative"

  if [ ! -f "$src" ]; then
    printf '  skip  %-44s (not in repo)\n' "$relative_path"
    return
  fi

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    printf '  ok    %-44s (already linked)\n' "$relative_path"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$(dirname "$backup")"
    mv "$dest" "$backup"
    printf '  back  %-44s -> %s\n' "$relative_path" "$backup"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  printf '  link  %-44s -> %s\n' "$relative_path" "$src"
}

configure_pi_theme() {
  local settings_dir="$HOME/.pi/agent"
  local settings_file="$settings_dir/settings.json"
  local tmp_file

  mkdir -p "$settings_dir"
  if [ -f "$settings_file" ]; then
    if ! command -v jq >/dev/null 2>&1; then
      printf '  skip  %-44s (jq not installed)\n' "pi theme selection"
      return
    fi

    tmp_file=$(mktemp)
    jq '.theme = "rose-pine-dawn/solitude"' "$settings_file" >"$tmp_file"
    mv "$tmp_file" "$settings_file"
  else
    printf '{\n  "theme": "rose-pine-dawn/solitude"\n}\n' >"$settings_file"
  fi

  printf '  set   %-44s -> rose-pine-dawn/solitude\n' "pi theme selection"
}

link_agent_skill() {
  local agent="$1"
  local skills_dir="$2"
  local skill="$3"
  local src="$REPO_DIR/opencode/skills/$skill"
  local dest="$skills_dir/$skill"
  local backup="$BACKUP_DIR/agent-skills/$agent/$skill"

  if [ ! -f "$src/SKILL.md" ]; then
    printf '  skip  %-44s (not in repo)\n' "$agent/$skill"
    return
  fi

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    printf '  ok    %-44s (already linked)\n' "$agent/$skill"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$(dirname "$backup")"
    mv "$dest" "$backup"
    printf '  back  %-44s -> %s\n' "$agent/$skill" "$backup"
  fi

  mkdir -p "$skills_dir"
  ln -s "$src" "$dest"
  printf '  link  %-44s -> %s\n' "$agent/$skill" "$src"
}

reconcile_agent_skills() {
  local agent="$1"
  local skills_dir="$2"
  local dest target skill keep candidate

  for dest in "$skills_dir"/*; do
    [ -L "$dest" ] || continue
    target="$(readlink -f "$dest" 2>/dev/null || true)"
    case "$target" in
      "$REPO_DIR"/opencode/skills/*) ;;
      *) continue ;;
    esac

    skill="$(basename "$dest")"
    keep=false
    for candidate in "${AGENT_SKILLS[@]}"; do
      if [ "$skill" = "$candidate" ]; then
        keep=true
        break
      fi
    done

    if [ "$keep" = false ]; then
      rm "$dest"
      printf '  clean %-44s (no longer shared)\n' "$agent/$skill"
    fi
  done
}

remove_legacy_skill_link() {
  local agent="$1"
  local skills_dir="$2"
  local skill="$3"
  local dest="$skills_dir/$skill"
  local backup="$BACKUP_DIR/agent-skills/$agent/$skill"

  if [ -L "$dest" ]; then
    rm "$dest"
    printf '  clean %-44s (legacy link removed)\n' "$agent/$skill"
  elif [ -e "$dest" ]; then
    mkdir -p "$(dirname "$backup")"
    mv "$dest" "$backup"
    printf '  back  %-44s -> %s\n' "$agent/$skill" "$backup"
  fi
}

install_solitude_theme() {
  local theme_url="https://github.com/HANCORE-linux/omarchy-solitude-theme.git"
  local theme_revision="7c3e45eec3e1c5eba24e6d08844e6bc1231b839d"
  local theme_dir="$CONFIG_DIR/omarchy/themes/solitude"
  local patch_file="$REPO_DIR/omarchy/solitude.patch"

  if [ ! -f "$patch_file" ]; then
    printf '  skip  %-44s (patch not in repo)\n' "omarchy/themes/solitude"
    return
  fi

  if [ ! -d "$theme_dir/.git" ]; then
    if [ -e "$theme_dir" ] || [ -L "$theme_dir" ]; then
      local backup="$BACKUP_DIR/omarchy/themes/solitude"
      mkdir -p "$(dirname "$backup")"
      mv "$theme_dir" "$backup"
      printf '  back  %-44s -> %s\n' "omarchy/themes/solitude" "$backup"
    fi

    mkdir -p "$(dirname "$theme_dir")"
    git clone --quiet "$theme_url" "$theme_dir"
    git -C "$theme_dir" checkout --quiet "$theme_revision"
    printf '  clone %-44s -> %s\n' "omarchy/themes/solitude" "$theme_dir"
  fi

  if git -C "$theme_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
    printf '  ok    %-44s (custom patch already applied)\n' "omarchy/themes/solitude"
  elif git -C "$theme_dir" apply --check "$patch_file" >/dev/null 2>&1; then
    git -C "$theme_dir" apply "$patch_file"
    printf '  patch %-44s -> readability overrides\n' "omarchy/themes/solitude"
  else
    printf '  error %-44s (custom patch conflicts with installed theme)\n' "omarchy/themes/solitude" >&2
    return 1
  fi
}

echo "Dotfiles : $REPO_DIR"
echo "Target   : $CONFIG_DIR"
echo
mkdir -p "$CONFIG_DIR"
for c in "${CONFIGS[@]}"; do link "$c"; done
for f in "${CONFIG_FILES[@]}"; do link_file "$f"; done
for f in "${OMARCHY_FILES[@]}"; do link_file "$f"; done
reconcile_agent_skills "agents" "$HOME/.agents/skills"
reconcile_agent_skills "codex" "$HOME/.codex/skills"
reconcile_agent_skills "pi" "$HOME/.pi/agent/skills"
for skill in test_quality tiger_style; do
  remove_legacy_skill_link "agents" "$HOME/.agents/skills" "$skill"
  remove_legacy_skill_link "codex" "$HOME/.codex/skills" "$skill"
  remove_legacy_skill_link "pi" "$HOME/.pi/agent/skills" "$skill"
done
for skill in "${AGENT_SKILLS[@]}"; do
  # Kimi CLI and Grok CLI both discover the shared Agent Skills directory.
  link_agent_skill "agents" "$HOME/.agents/skills" "$skill"
  link_agent_skill "codex" "$HOME/.codex/skills" "$skill"
  link_agent_skill "pi" "$HOME/.pi/agent/skills" "$skill"
done
install_solitude_theme
link_external_file "pi/themes/solitude.json" "$HOME/.pi/agent/themes/solitude.json" "pi-agent/themes/solitude.json"
link_external_file "pi/themes/rose-pine-dawn.json" "$HOME/.pi/agent/themes/rose-pine-dawn.json" "pi-agent/themes/rose-pine-dawn.json"
configure_pi_theme
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
  - Solitude theme      : run `omarchy theme set solitude` to regenerate all
                          app themes after first install.
NOTE
