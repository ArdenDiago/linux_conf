#!/usr/bin/env bash
#
# Firefox is in the official extra repo on Arch. This only installs the
# browser — custom userChrome.css theming lives in firefox-themes/ and is
# applied separately, not by this script.
#
MODULE_DESC="Firefox"

module_step() {
  pac_install firefox
}
