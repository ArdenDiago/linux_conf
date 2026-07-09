#!/usr/bin/env bash
#
# waybar theme: v7 by atif-1402 (github.com/atif-1402/minimal-waybar-themes),
# with its Omarchy-only modules (logo menu, power launcher, update checker,
# idle/DND/screen-recording indicators) swapped for plain equivalents or
# dropped where there's no non-Omarchy substitute. The wifi/bluetooth
# launchers do get a plain-Arch equivalent — see network-menu.sh and
# bluetooth-menu.sh below — since nmcli/bluetoothctl + fuzzel cover them
# fully without needing anything Omarchy-specific.
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
# The network/bluetooth modules themselves ship with waybar and only need
# NetworkManager/bluez's D-Bus services to report status — but *clicking*
# them (network-menu.sh, bluetooth-menu.sh) drives nmcli/bluetoothctl
# directly to scan and (dis)connect, and pops the result in a fuzzel
# dropdown with notify-send (libnotify) feedback, so those are real deps
# here too, not just nice-to-haves. polkit-gnome (already spawned by
# modules/15-hyprland.sh and modules/16-niri.sh) supplies the auth agent
# NetworkManager needs for some operations.
#
# custom/media-spectrum is a persistent module (media-spectrum.py) that
# streams a small cava spectrum graph — rendered as block-character bars,
# cava-spectrum.conf is its cava config — while something is playing, and
# hides itself otherwise. Its on-click (media-boost-toggle.sh) toggles a
# bass-boost EQ by loading the bundled bassboost.json preset into
# EasyEffects (started in --service-mode so it runs headless) and flipping
# global bypass; the module's own "boosted" CSS class reflects the state.
# custom/media-prev/-playpause/-next (media-button.sh) sit next to it and
# hide themselves the same way when nothing is playing.
#
MODULE_DESC="Dotfiles (waybar — v7 theme)"

module_step() {
  local src="$SCRIPT_DIR/dotfiles/waybar"

  pac_install waybar playerctl jq pamixer ttf-jetbrains-mono-nerd pacman-contrib \
    networkmanager bluez bluez-utils libnotify easyeffects cava || return 1

  track_rollback "sudo systemctl disable --now NetworkManager.service 2>/dev/null || true"
  sudo systemctl enable --now NetworkManager.service || return 1

  track_rollback "sudo systemctl disable --now bluetooth.service 2>/dev/null || true"
  sudo systemctl enable --now bluetooth.service || return 1

  mkdir -p "$HOME/.config/waybar"
  # EasyEffects 8.x (Qt) reads presets from XDG_DATA_HOME, not
  # ~/.config/easyeffects — confirmed by watching it auto-migrate a preset
  # dropped in the old ~/.config location into this one on startup.
  mkdir -p "$HOME/.local/share/easyeffects/output"

  install_dotfile "$src/config-hyprland.jsonc"   "$HOME/.config/waybar/config-hyprland.jsonc"
  install_dotfile "$src/config-niri.jsonc"       "$HOME/.config/waybar/config-niri.jsonc"
  install_dotfile "$src/style.css"               "$HOME/.config/waybar/style.css"
  install_dotfile "$src/clock.sh"                "$HOME/.config/waybar/clock.sh"
  install_dotfile "$src/update.sh"               "$HOME/.config/waybar/update.sh"
  install_dotfile "$src/window-hyprland.sh"      "$HOME/.config/waybar/window-hyprland.sh"
  install_dotfile "$src/window-niri.sh"          "$HOME/.config/waybar/window-niri.sh"
  install_dotfile "$src/network-menu.sh"         "$HOME/.config/waybar/network-menu.sh"
  install_dotfile "$src/bluetooth-menu.sh"       "$HOME/.config/waybar/bluetooth-menu.sh"
  install_dotfile "$src/cava-spectrum.conf"      "$HOME/.config/waybar/cava-spectrum.conf"
  install_dotfile "$src/media-spectrum.py"       "$HOME/.config/waybar/media-spectrum.py"
  install_dotfile "$src/media-button.sh"         "$HOME/.config/waybar/media-button.sh"
  install_dotfile "$src/media-boost-toggle.sh"   "$HOME/.config/waybar/media-boost-toggle.sh"
  install_dotfile "$src/bassboost.json"          "$HOME/.local/share/easyeffects/output/bassboost.json"

  chmod +x "$HOME/.config/waybar/"{clock.sh,update.sh,window-hyprland.sh,window-niri.sh,network-menu.sh,bluetooth-menu.sh,media-spectrum.py,media-button.sh,media-boost-toggle.sh}

  if pgrep -x waybar &>/dev/null; then
    warn "waybar is already running — 'pkill -SIGUSR2 waybar' reloads it quickly, but a full restart (or re-login) is the reliable way to pick up config changes."
  fi
  return 0
}
