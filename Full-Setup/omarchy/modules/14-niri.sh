#!/usr/bin/env bash
#
# Niri (scrollable-tiling Wayland compositor) as an optional alternative to
# Omarchy's default Hyprland session. Unlike Pop!_OS/Ubuntu, niri is a
# proper package in Arch's official extra repo — no building from source,
# no manual session-file install. Companion tools listed here are niri's
# own documented optional dependencies (launcher, notifications, lock
# screen, bar, X11 app support).
#
# No polkit agent is installed here: Omarchy's existing Hyprland session
# already runs one, and niri will reuse it.
#
MODULE_DESC="Niri (optional, alongside Hyprland)"

module_step() {
  pac_install niri fuzzel mako swaybg swaylock waybar xwayland-satellite || return 1

  if lspci | grep -qi nvidia; then
    warn "There is a known niri+NVIDIA high-VRAM-usage quirk (heap reuse);"
    warn "  see the niri wiki's NVIDIA section if you see excessive VRAM use."
    warn "For hybrid graphics PRIME offload, launch apps with:"
    warn "  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>"
  fi

  log "Niri installed alongside Hyprland. Log out and pick 'Niri' from your"
  log "display manager's session menu to try it — your existing Hyprland"
  log "session is untouched."
  return 0
}
