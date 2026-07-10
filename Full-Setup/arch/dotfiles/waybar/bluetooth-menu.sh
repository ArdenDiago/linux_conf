#!/usr/bin/env bash
# custom/bluetooth click handler — bound to the "bluetooth" module's
# on-click in config-hyprland.jsonc / config-niri.jsonc. Pops a fuzzel
# dropdown listing paired/connected devices and anything nearby, with
# entries to scan and toggle the adapter.
#
# `bluetoothctl devices` lists every device bluez currently knows about
# (paired ones plus anything seen during the last scan, until it ages
# out), so a plain scan is enough to populate "new" devices without a
# separate discovery-vs-paired code path.
#
# Scan/toggle actions loop back into a fresh menu (you're still
# browsing); picking a device to (dis)connect exits after one
# notify-send, matching network-menu.sh's behavior.

set -uo pipefail

LOCK_FILE="/tmp/bluetooth-menu-$UID.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

REFRESH="󰑐  Scan for devices"
TOGGLE_OFF="󰂯  Turn Bluetooth Off"
TOGGLE_ON="󰂲  Turn Bluetooth On"

notify() { notify-send -a "Bluetooth" "$@" 2>/dev/null || true; }

powered() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes"
}

while true; do
    declare -A KIND=() IDENT=()
    lines=()

    if ! powered; then
        lines=("$TOGGLE_ON")
    else
        lines+=("$REFRESH" "$TOGGLE_OFF")

        mapfile -t connected_lines < <(bluetoothctl devices Connected 2>/dev/null)
        connected_macs=()
        first=1
        for l in "${connected_lines[@]}"; do
            [[ "$l" == Device\ * ]] || continue
            mac="$(awk '{print $2}' <<<"$l")"
            name="$(cut -d' ' -f3- <<<"$l")"
            [ "$first" -eq 1 ] && { lines+=("── Connected ──"); first=0; }
            line="  $name"
            lines+=("$line")
            KIND["$line"]="connected"
            IDENT["$line"]="$mac"
            connected_macs+=("$mac")
        done

        mapfile -t all_lines < <(bluetoothctl devices 2>/dev/null)
        first=1
        for l in "${all_lines[@]}"; do
            [[ "$l" == Device\ * ]] || continue
            mac="$(awk '{print $2}' <<<"$l")"
            name="$(cut -d' ' -f3- <<<"$l")"
            printf -v is_connected '%s' " ${connected_macs[*]-} "
            [[ "$is_connected" == *" $mac "* ]] && continue
            [ "$first" -eq 1 ] && { lines+=("── Available ──"); first=0; }
            line="󰂯  $name"
            lines+=("$line")
            KIND["$line"]="available"
            IDENT["$line"]="$mac"
        done
    fi

    choice="$(printf '%s\n' "${lines[@]}" | fuzzel --dmenu --prompt " " --lines=12)"
    [ -z "$choice" ] && exit 0

    case "$choice" in
        "$REFRESH")
            bluetoothctl --timeout 4 scan on &>/dev/null
            continue
            ;;
        "$TOGGLE_OFF")
            bluetoothctl power off &>/dev/null
            notify "Bluetooth turned off"
            continue
            ;;
        "$TOGGLE_ON")
            bluetoothctl power on &>/dev/null
            notify "Bluetooth turned on"
            continue
            ;;
        "── Connected ──"|"── Available ──")
            continue
            ;;
    esac

    kind="${KIND[$choice]-}"
    mac="${IDENT[$choice]-}"
    [ -z "$kind" ] && exit 0
    name="${choice#* }"
    name="${name#  }"

    if [ "$kind" = "connected" ]; then
        bluetoothctl disconnect "$mac" &>/dev/null \
            && notify "Disconnected" "$name" \
            || notify "Failed to disconnect" "$name"
    else
        bluetoothctl trust "$mac" &>/dev/null
        if bluetoothctl pair "$mac" &>/dev/null && bluetoothctl connect "$mac" &>/dev/null; then
            notify "Connected" "$name"
        else
            notify "Failed to connect" "$name"
        fi
    fi
    exit 0
done
