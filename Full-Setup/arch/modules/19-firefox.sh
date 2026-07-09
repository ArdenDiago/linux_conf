#!/usr/bin/env bash
#
# Firefox is in the official extra repo on Arch. This only installs the
# browser — custom userChrome.css theming lives in firefox-themes/ and is
# applied separately, not by this script.
#
# The niri/Wayland fixes (native Wayland rendering, screen-share, file
# picker) live in modules/16-niri.sh instead, since they're env vars and
# a portal config that niri itself needs to own, not something scoped to
# the Firefox package. See that module and dotfiles/niri/niri-portals.conf.
#
MODULE_DESC="Firefox"

module_step() {
  pac_install firefox
}
