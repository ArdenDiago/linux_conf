#!/usr/bin/env bash
#
# waybar theme: v7 by atif-1402 (github.com/atif-1402/minimal-waybar-themes),
# with its Omarchy-only modules (logo menu, wifi/bluetooth/power launchers,
# update checker, idle/DND/screen-recording indicators) swapped for plain
# equivalents or dropped where there's no non-Omarchy substitute.
#
# Two configs — config-hyprland.jsonc and config-niri.jsonc — since the two
# sessions need different workspace modules (hyprland/workspaces vs
# niri/workspaces) and different custom/active_window scripts (hyprctl vs
# `niri msg`). Each compositor's own dotfile (modules/15-hyprland.sh,
# modules/16-niri.sh) already points its exec-once/spawn-at-startup at the
# right one via -c, so waybar always loads the config matching whichever
# session you're actually in. custom/gamemode (toggles Hyprland's
# animations/blur via `hyprctl keyword`) only exists in the Hyprland config
# — niri has no equivalent live-reconfigure IPC.
#
# playerctl backs the media widget, jq backs the active-window script,
# pamixer backs the pulseaudio module's right-click mute toggle,
# pacman-contrib's checkupdates backs the update indicator, and the Nerd
# Font is what actually renders all the glyph icons used throughout.
#
MODULE_DESC="Dotfiles (waybar — v7 theme)"

module_step() {
  local src="$SCRIPT_DIR/dotfiles/waybar"

  pac_install waybar playerctl jq pamixer ttf-jetbrains-mono-nerd pacman-contrib || return 1

  mkdir -p "$HOME/.config/waybar"

  install_dotfile "$src/config-hyprland.jsonc" "$HOME/.config/waybar/config-hyprland.jsonc"
  install_dotfile "$src/config-niri.jsonc"     "$HOME/.config/waybar/config-niri.jsonc"
  install_dotfile "$src/style.css"             "$HOME/.config/waybar/style.css"
  install_dotfile "$src/clock.sh"              "$HOME/.config/waybar/clock.sh"
  install_dotfile "$src/update.sh"             "$HOME/.config/waybar/update.sh"
  install_dotfile "$src/window-hyprland.sh"    "$HOME/.config/waybar/window-hyprland.sh"
  install_dotfile "$src/window-niri.sh"        "$HOME/.config/waybar/window-niri.sh"

  chmod +x "$HOME/.config/waybar/"{clock.sh,update.sh,window-hyprland.sh,window-niri.sh}

  if pgrep -x waybar &>/dev/null; then
    warn "waybar is already running — 'pkill -SIGUSR2 waybar' reloads it quickly, but a full restart (or re-login) is the reliable way to pick up config changes."
  fi
  return 0
}
