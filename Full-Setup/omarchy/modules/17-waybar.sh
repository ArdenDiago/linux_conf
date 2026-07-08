#!/usr/bin/env bash
#
# Personal waybar setup: a themed status bar built around Omarchy's own
# bundled helpers (omarchy-menu, omarchy-theme-current, the $OMARCHY_PATH
# scripts, etc.) and Hyprland-specific modules (hyprland/workspaces,
# hyprctl), so this is meant for Omarchy's default Hyprland session, not
# the optional Niri one. waybar itself already ships as part of a stock
# Omarchy install; pac_install below is just a --needed no-op safety net
# in case this module ever runs standalone.
#
# playerctl + python back the custom media widget (mediaplayer.py polls
# playerctl for the current track); everything else the config calls
# (omarchy-*, hyprctl, $OMARCHY_PATH scripts) is provided by Omarchy itself.
#
MODULE_DESC="Dotfiles (waybar)"

module_step() {
  local src="$SCRIPT_DIR/dotfiles/waybar"

  pac_install waybar playerctl python || return 1

  mkdir -p "$HOME/.config/waybar"

  install_dotfile "$src/config.jsonc"   "$HOME/.config/waybar/config.jsonc"
  install_dotfile "$src/style.css"      "$HOME/.config/waybar/style.css"
  install_dotfile "$src/mediaplayer.py" "$HOME/.config/waybar/mediaplayer.py"

  chmod +x "$HOME/.config/waybar/mediaplayer.py"

  if pgrep -x waybar &>/dev/null; then
    warn "waybar is already running — 'pkill -SIGUSR2 waybar' reloads it quickly, but a full restart (or re-login) is the reliable way to pick up config.jsonc changes."
  fi
  return 0
}
