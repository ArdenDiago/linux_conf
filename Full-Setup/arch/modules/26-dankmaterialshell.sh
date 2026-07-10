#!/usr/bin/env bash
#
# DankMaterialShell (DMS) — a Quickshell-based desktop shell (Material 3
# bar/dock/launcher/notification center/etc.) that's replaced waybar as the
# actual panel for both sessions; see modules/17-desktop-services.sh for the
# services (NetworkManager, bluetooth, media/update CLI tools) waybar used
# to bundle in that DMS's widgets still lean on.
#
# dms-shell is the core package; dms-shell-hyprland and dms-shell-niri are
# thin per-compositor integration packages (matugen templates, layout
# fragments under ~/.config/{hypr,niri}/dms/) — both installed side by side
# for the same reason modules/15-hyprland.sh and modules/16-niri.sh install
# both sessions: only one runs at a time (picked at SDDM login), but either
# should work out of the box. All three are in Arch's official `extra`
# repo, no AUR build needed.
#
# matugen (dynamic wallpaper-based theming), power-profiles-daemon (the
# power-profile OSD/toggle), and qt6-multimedia (UI sound effects) are
# optional deps DMS actually uses here, so they're installed explicitly
# rather than left to chance.
#
# Only settings.json gets deployed as a dotfile — it's the one file here
# that's genuinely hand-tuned preference data (theme, bar/dock layout and
# sizing, workspace/notification behavior, etc.), not something DMS
# regenerates on its own. The matugen-generated theme fragments
# (~/.config/{hypr,niri}/dms/*, ~/.config/DankMaterialShell/firefox.css)
# are deliberately left alone — DMS (re)writes those itself from the
# current theme + settings.json, and a frozen copy in this repo would just
# go stale the moment the theme changes.
#
# dms.service (ships with the dms-shell package) is only *enabled* here,
# not started — it Requisites=graphical-session.target, which doesn't
# exist yet when this script runs from a TTY before any session has
# logged in; it starts on its own at the next graphical login.
#
# dms.service.override.conf works around a real conflict: the unit is
# Type=dbus, BusName=org.freedesktop.Notifications, but mako (started by
# modules/15-hyprland.sh / modules/16-niri.sh's exec-once/spawn-at-startup)
# already owns that name — so the moment systemd actually starts dms.service
# itself (rather than something else launching the process directly, which
# is how it happened to be running before this override existed), the
# BusName wait times out and it crash-loops forever. Type=simple drops that
# wait; see the override file itself for the full story.
#
MODULE_DESC="DankMaterialShell (Quickshell desktop shell)"

module_step() {
  pac_install dms-shell dms-shell-hyprland dms-shell-niri \
    matugen power-profiles-daemon qt6-multimedia || return 1

  mkdir -p "$HOME/.config/systemd/user/dms.service.d"
  install_dotfile "$SCRIPT_DIR/dotfiles/dankmaterialshell/dms.service.override.conf" \
    "$HOME/.config/systemd/user/dms.service.d/override.conf"
  systemctl --user daemon-reload

  track_rollback "systemctl --user disable dms.service 2>/dev/null || true"
  systemctl --user enable dms.service || return 1

  mkdir -p "$HOME/.config/DankMaterialShell"
  install_dotfile "$SCRIPT_DIR/dotfiles/dankmaterialshell/settings.json" \
    "$HOME/.config/DankMaterialShell/settings.json"

  if pgrep -x dms &>/dev/null; then
    log "DMS is already running — 'systemctl --user reload dms.service' picks up settings.json changes without a full restart."
  fi
  return 0
}
