#!/usr/bin/env bash
# custom/network click handler — bound to the "network" module's on-click
# in config-hyprland.jsonc / config-niri.jsonc. Pops a fuzzel dropdown
# listing what's currently connected (wifi + ethernet) and nearby wifi
# networks, with entries to rescan and toggle the wifi radio.
#
# nmcli's terse `-m multiline` output is used instead of the default
# single-line `-t` form and parsed by fixed record size (mapfile + a
# stepped for-loop) rather than by splitting on ':' — real SSIDs around
# here contain literal colons/spaces ("Orio A BLOCK 1st floor "), so a
# naive `awk -F:` or field-count split would corrupt names. Each record's
# fields are pulled by stripping the known "KEY:" prefix instead, which
# only ever matches once at the start of the line.
#
# Scan/toggle actions loop back into a fresh menu (you're still
# browsing); picking a network to (dis)connect exits after one
# notify-send, matching how the equivalent Omarchy click-menu behaves.

set -uo pipefail

LOCK_FILE="/tmp/network-menu-$UID.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

REFRESH="󰑐  Scan for networks"
TOGGLE_OFF="󰤮  Turn Wifi Off"
TOGGLE_ON="󰤯  Turn Wifi On"

notify() { notify-send -a "Network" "$@" 2>/dev/null || true; }

signal_icon() {
    local s="$1"
    if   [ "$s" -ge 80 ]; then echo "󰤨"
    elif [ "$s" -ge 60 ]; then echo "󰤥"
    elif [ "$s" -ge 40 ]; then echo "󰤢"
    elif [ "$s" -ge 20 ]; then echo "󰤟"
    else echo "󰤯"
    fi
}

while true; do
    declare -A KIND=() IDENT=()
    lines=()

    radio="$(nmcli -t -f WIFI radio 2>/dev/null)"

    if [ "$radio" = "disabled" ]; then
        lines+=("$REFRESH" "$TOGGLE_ON")
    else
        lines+=("$REFRESH" "$TOGGLE_OFF")

        mapfile -t con_lines < <(nmcli -t -m multiline -f NAME,TYPE con show --active 2>/dev/null)
        connected_names=()
        first=1
        for ((i = 0; i + 1 < ${#con_lines[@]}; i += 2)); do
            name="${con_lines[i]#NAME:}"
            type="${con_lines[i + 1]#TYPE:}"
            case "$type" in
                802-11-wireless) icon="󰤨" ;;
                802-3-ethernet)  icon="󰌘" ;;
                *) continue ;;
            esac
            [ "$first" -eq 1 ] && { lines+=("── Connected ──"); first=0; }
            line="$icon  $name"
            lines+=("$line")
            KIND["$line"]="connected"
            IDENT["$line"]="$name"
            connected_names+=("$name")
        done

        mapfile -t wifi_lines < <(nmcli -t -m multiline -f active,ssid,security,signal dev wifi list 2>/dev/null)
        declare -A best_signal=() best_secured=()
        for ((i = 0; i + 3 < ${#wifi_lines[@]}; i += 4)); do
            active="${wifi_lines[i]#ACTIVE:}"
            ssid="${wifi_lines[i + 1]#SSID:}"
            security="${wifi_lines[i + 2]#SECURITY:}"
            signal="${wifi_lines[i + 3]#SIGNAL:}"
            [ "$active" = "yes" ] && continue
            [ -z "$ssid" ] && continue
            printf -v is_connected '%s' " ${connected_names[*]-} "
            [[ "$is_connected" == *" $ssid "* ]] && continue
            if [ -z "${best_signal[$ssid]+x}" ] || [ "$signal" -gt "${best_signal[$ssid]}" ]; then
                best_signal["$ssid"]="$signal"
                best_secured["$ssid"]="$security"
            fi
        done

        first=1
        for ssid in "${!best_signal[@]}"; do
            signal="${best_signal[$ssid]}"
            lock=""
            [ -n "${best_secured[$ssid]}" ] && lock="󰌾 "
            line="$(signal_icon "$signal")  ${lock}${ssid} (${signal}%)"
            [ "$first" -eq 1 ] && { lines+=("── Available ──"); first=0; }
            lines+=("$line")
            KIND["$line"]="available"
            IDENT["$line"]="$ssid"
        done
    fi

    choice="$(printf '%s\n' "${lines[@]}" | fuzzel --dmenu --prompt " " --lines=12)"
    [ -z "$choice" ] && exit 0

    case "$choice" in
        "$REFRESH")
            nmcli device wifi rescan &>/dev/null
            sleep 2
            continue
            ;;
        "$TOGGLE_OFF")
            nmcli radio wifi off &>/dev/null
            notify "Wifi turned off"
            continue
            ;;
        "$TOGGLE_ON")
            nmcli radio wifi on &>/dev/null
            notify "Wifi turned on"
            sleep 2
            continue
            ;;
        "── Connected ──"|"── Available ──")
            continue
            ;;
    esac

    kind="${KIND[$choice]-}"
    ident="${IDENT[$choice]-}"
    [ -z "$kind" ] && exit 0

    if [ "$kind" = "connected" ]; then
        nmcli connection down "$ident" &>/dev/null \
            && notify "Disconnected" "$ident" \
            || notify "Failed to disconnect" "$ident"
        exit 0
    fi

    if nmcli device wifi connect "$ident" &>/dev/null; then
        notify "Connected" "$ident"
    else
        password="$(fuzzel --dmenu --password --prompt "Password for $ident: " < /dev/null)"
        if [ -n "$password" ] && nmcli device wifi connect "$ident" password "$password" &>/dev/null; then
            notify "Connected" "$ident"
        else
            notify "Failed to connect" "$ident"
        fi
    fi
    exit 0
done
