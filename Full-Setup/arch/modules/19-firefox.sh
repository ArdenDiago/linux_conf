#!/usr/bin/env bash
#
# Firefox, plus the two personal customizations that used to require
# fully manual setup (firefox-themes/ and firefox-newtab-pomodoro/, both
# at the repo root, shared with the Omarchy setup):
#
#   - The hover-titlebar userChrome theme + its required about:config
#     prefs are fully automated below — copied into every profile found
#     in profiles.ini (or a fresh one, if none exists yet).
#
#   - The New Tab extension is packaged into a .xpi, ready to install,
#     but NOT force-installed automatically. Three different unattended
#     install paths were tried against a real running profile —
#     enterprise policy ExtensionSettings, an unpacked-directory
#     sideload, and a .xpi dropped straight into extensions/ — and none
#     of them actually showed up in the profile's extensions.json on
#     this Firefox version, which locks down unsigned-extension
#     sideloading harder than the older docs for those methods suggest.
#     Rather than ship automation that silently doesn't work, this
#     stays a single manual step (logged below, and in this module's
#     comments): about:addons -> gear icon -> Install Add-on From File.
#
# The niri/Wayland fixes (native Wayland rendering, screen-share, file
# picker) live in modules/16-niri.sh instead, since they're env vars and
# a portal config that niri itself needs to own, not something scoped to
# the Firefox package. See that module and dotfiles/niri/niri-portals.conf.
#
MODULE_DESC="Firefox"

FIREFOX_THEME_SRC="$SCRIPT_DIR/../../firefox-themes"
FIREFOX_EXT_SRC="$SCRIPT_DIR/../../firefox-newtab-pomodoro"
FIREFOX_EXT_ID="newtab-pomodoro@linux-conf.local"

# _ensure_user_pref <file> <name> <value>
# Idempotently ensures a user_pref line exists in a Firefox prefs file,
# replacing any existing line for the same pref instead of duplicating
# it or clobbering whatever else is already in the file.
_ensure_user_pref() {
  local file="$1" name="$2" value="$3"
  local line="user_pref(\"$name\", $value);"
  touch "$file"
  if grep -q "\"$name\"" "$file"; then
    sed -i "s|.*\"$name\".*|$line|" "$file"
  else
    echo "$line" >> "$file"
  fi
}

# _setup_profile <profile-dir>
# Copies the theme into <profile>/chrome/ (source of truth is the repo —
# a re-run always overwrites, same as install_dotfile would for a single
# file) and idempotently sets every pref the theme's own README says it
# needs, plus xpinstall.signatures.required=false so the one remaining
# manual "Install Add-on From File" step below will actually accept our
# unsigned .xpi instead of rejecting it.
_setup_profile() {
  local profile_dir="$1"
  mkdir -p "$profile_dir/chrome"
  cp -r "$FIREFOX_THEME_SRC"/. "$profile_dir/chrome/"

  _ensure_user_pref "$profile_dir/user.js" "toolkit.legacyUserProfileCustomizations.stylesheets" "true"
  _ensure_user_pref "$profile_dir/user.js" "browser.tabs.inTitlebar" "1"
  _ensure_user_pref "$profile_dir/user.js" "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" "false"
  _ensure_user_pref "$profile_dir/user.js" "browser.newtabpage.activity-stream.showWeather" "false"
  _ensure_user_pref "$profile_dir/user.js" "browser.newtabpage.activity-stream.system.showWeather" "false"
  _ensure_user_pref "$profile_dir/user.js" "xpinstall.signatures.required" "false"
  _ensure_user_pref "$profile_dir/user.js" "layout.css.devPixelsPerPx" "1"
}

module_step() {
  pac_install firefox zip || return 1

  local moz_dir="$HOME/.mozilla/firefox"
  local profiles_ini="$moz_dir/profiles.ini"
  mkdir -p "$moz_dir"

  if [ ! -f "$profiles_ini" ]; then
    log "No Firefox profile yet — creating one."
    mkdir -p "$moz_dir/default-release"
    cat > "$profiles_ini" << 'EOF'
[Profile0]
Name=default
IsRelative=1
Path=default-release
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF
  fi

  local rel_path found=0
  while IFS= read -r rel_path; do
    found=1
    _setup_profile "$moz_dir/$rel_path"
    log "Applied theme + prefs to profile: $rel_path"
  done < <(grep -oP '^Path=\K.*' "$profiles_ini")

  if [ "$found" -eq 0 ]; then
    warn "Could not find any profile path in $profiles_ini — theme not applied."
  fi

  local ext_dir="$HOME/.local/share/firefox-extensions"
  local xpi="$ext_dir/$FIREFOX_EXT_ID.xpi"
  mkdir -p "$ext_dir"

  if [ ! -f "$xpi" ] || [ "$FIREFOX_EXT_SRC/manifest.json" -nt "$xpi" ]; then
    rm -f "$xpi"
    (cd "$FIREFOX_EXT_SRC" && zip -qr "$xpi" .) || return 1
    log "Packaged New Tab extension: $xpi"
  fi

  log "One manual step left for the New Tab extension (about:addons won't"
  log "  let an unattended script click through its own file picker):"
  log "  about:addons -> gear icon (top right) -> Install Add-on From File"
  log "  -> select $xpi"

  if pgrep -x firefox &>/dev/null; then
    warn "Firefox is running — restart it for the theme/prefs to take effect."
  fi

  return 0
}
