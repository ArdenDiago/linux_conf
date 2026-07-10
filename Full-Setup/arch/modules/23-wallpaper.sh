#!/usr/bin/env bash
#
# Multi-wallpaper switcher: drop images into ~/Pictures/Wallpapers, hit
# Super+W (Hyprland) / Mod+W (niri), and fuzzel pops up a picker of actual
# image previews (not filenames) for everything in that folder — whatever
# gets picked is applied immediately via swaybg and remembered in
# ~/.config/wallpaper/current so it survives a logout/reboot instead of
# resetting to a solid color.
#
# swaybg and fuzzel are already installed by modules/15-hyprland.sh and
# modules/16-niri.sh. imagemagick is new here: fuzzel's icon loader only
# supports PNG/SVG, not JPEG, so select.sh generates a small PNG thumbnail
# per wallpaper (cached under ~/.cache/wallpaper-thumbs/) to actually show
# as the preview. This module only wires select.sh (the picker) and
# restore.sh (session-startup restore) into place; the actual Super+W /
# Mod+W bindings and the exec-once/spawn-at-startup swap live in
# dotfiles/hypr/hyprland.conf and dotfiles/niri/config.kdl themselves.
#
# Deliberately does not touch the SDDM login-screen theme (modules/22) —
# that's a separate, unrelated background.
#
MODULE_DESC="Wallpaper switcher"

module_step() {
  local src="$SCRIPT_DIR/dotfiles/wallpaper"

  pac_install imagemagick || return 1

  mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/.config/wallpaper" "$HOME/.cache/wallpaper-thumbs"

  install_dotfile "$src/select.sh"  "$HOME/.config/wallpaper/select.sh"
  install_dotfile "$src/restore.sh" "$HOME/.config/wallpaper/restore.sh"

  chmod +x "$HOME/.config/wallpaper/"{select.sh,restore.sh}

  if [ -z "$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f 2>/dev/null)" ]; then
    log "~/Pictures/Wallpapers is empty — drop some images in, then press Super+W (Hyprland) or Mod+W (niri) to pick one."
  fi
  return 0
}
