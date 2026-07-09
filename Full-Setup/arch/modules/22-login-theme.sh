#!/usr/bin/env bash
#
# SDDM login theme: Qylock's "Pixel · Night City" (github.com/Darkkal44/qylock).
# Fetches only the six files this one theme needs (Main.qml,
# BackgroundVideo.qml, bg.mp4, theme.conf, metadata.desktop, its bundled
# font) directly from the repo instead of cloning the whole thing — qylock
# ships dozens of themes, most with their own multi-MB video backgrounds,
# and the login screen only ever shows the one we activate.
#
# The theme's BackgroundVideo.qml plays bg.mp4 through QtMultimedia, which
# on Linux needs a GStreamer/ffmpeg backend to actually decode video, and
# Main.qml's DropShadow effects come from Qt5Compat.GraphicalEffects
# (qt6-5compat). Dependency list is straight from the repo's own
# SDDM-setup instructions: github.com/Darkkal44/qylock#sddm-setup.
#
MODULE_DESC="Login screen theme (Qylock — Pixel · Night City)"

QYLOCK_THEME="pixel-night-city"
QYLOCK_RAW="https://raw.githubusercontent.com/Darkkal44/qylock/main/themes/$QYLOCK_THEME"
QYLOCK_SYSTEM_DIR="/usr/share/sddm/themes/$QYLOCK_THEME"
QYLOCK_CONF="/etc/sddm.conf.d/theme.conf"

module_step() {
  pac_install qt6-declarative qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg \
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly || return 1

  if [ -f "$QYLOCK_SYSTEM_DIR/theme.conf" ] && \
     [ -f "$QYLOCK_CONF" ] && grep -q "^Current=$QYLOCK_THEME$" "$QYLOCK_CONF"; then
    log "'$QYLOCK_THEME' is already installed and active, skipping."
    return 0
  fi

  log "Downloading '$QYLOCK_THEME' from Qylock (github.com/Darkkal44/qylock)"
  local stage="$TMPDIR/qylock-$QYLOCK_THEME"
  mkdir -p "$stage/font"

  local f
  for f in Main.qml BackgroundVideo.qml theme.conf metadata.desktop; do
    curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL "$QYLOCK_RAW/$f" -o "$stage/$f" || return 1
  done
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL "$QYLOCK_RAW/bg.mp4" -o "$stage/bg.mp4" || return 1
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL \
    "$QYLOCK_RAW/font/PixelifySans-Bold.ttf" -o "$stage/font/PixelifySans-Bold.ttf" || return 1

  track_rollback "sudo rm -rf '$QYLOCK_SYSTEM_DIR'"
  sudo mkdir -p "$(dirname "$QYLOCK_SYSTEM_DIR")" || return 1
  sudo rm -rf "$QYLOCK_SYSTEM_DIR"
  sudo cp -r "$stage" "$QYLOCK_SYSTEM_DIR" || return 1
  log "Installed theme to $QYLOCK_SYSTEM_DIR"

  sudo mkdir -p "$(dirname "$QYLOCK_CONF")" || return 1
  if [ -f "$QYLOCK_CONF" ]; then
    if [ ! -f "$QYLOCK_CONF.bak" ]; then
      sudo cp "$QYLOCK_CONF" "$QYLOCK_CONF.bak"
      track_rollback "sudo mv -f '$QYLOCK_CONF.bak' '$QYLOCK_CONF' 2>/dev/null || true"
    fi
    if grep -q "^Current=" "$QYLOCK_CONF"; then
      sudo sed -i "s|^Current=.*|Current=$QYLOCK_THEME|" "$QYLOCK_CONF"
    elif grep -q "^\[Theme\]" "$QYLOCK_CONF"; then
      sudo sed -i "/^\[Theme\]/a Current=$QYLOCK_THEME" "$QYLOCK_CONF"
    else
      printf '\n[Theme]\nCurrent=%s\n' "$QYLOCK_THEME" | sudo tee -a "$QYLOCK_CONF" > /dev/null
    fi
  else
    track_rollback "sudo rm -f '$QYLOCK_CONF'"
    printf '[Theme]\nCurrent=%s\n' "$QYLOCK_THEME" | sudo tee "$QYLOCK_CONF" > /dev/null
  fi

  log "SDDM login screen set to '$QYLOCK_THEME' — takes effect at next login/reboot."
  return 0
}
