#!/bin/bash
# Toggles a bass-boost EQ on the default PipeWire sink via EasyEffects,
# on-click handler for the custom/media-spectrum waybar module.
# Requires an EasyEffects output preset named "bassboost" (see README note).
STATE_FILE="$HOME/.cache/waybar-media-boost"
PRESET="bassboost"

if ! pgrep -x easyeffects >/dev/null; then
    nohup easyeffects --service-mode --hide-window >/dev/null 2>&1 &
    disown
    sleep 1.5
fi

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    easyeffects -b 1 >/dev/null 2>&1
else
    easyeffects -l "$PRESET" >/dev/null 2>&1
    sleep 0.3
    easyeffects -b 2 >/dev/null 2>&1
    touch "$STATE_FILE"
fi
