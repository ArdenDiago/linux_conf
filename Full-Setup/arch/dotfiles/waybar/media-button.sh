#!/bin/bash
# usage: media-button.sh prev|playpause|next
# Polled every interval by waybar; hides itself when no player is active.
status=$(playerctl status 2>/dev/null)

if [ -z "$status" ]; then
    echo '{"text":"","class":"hidden"}'
    exit 0
fi

case "$1" in
    prev)
        echo '{"text":"󰒮","tooltip":"Previous"}'
        ;;
    next)
        echo '{"text":"󰒭","tooltip":"Next"}'
        ;;
    playpause)
        if [ "$status" = "Playing" ]; then
            echo '{"text":"󰏤","tooltip":"Pause"}'
        else
            echo '{"text":"󰐊","tooltip":"Play"}'
        fi
        ;;
esac
