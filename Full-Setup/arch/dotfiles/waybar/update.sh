#!/usr/bin/env bash
# custom/update module for the v7 theme — original theme used Omarchy's own
# omarchy-update-available helper; this is the plain pacman-contrib
# equivalent (same checkupdates approach as dotfiles/tmux/welcome.sh).

count=$(checkupdates --nosync 2>/dev/null | wc -l)

if [ "$count" -gt 0 ]; then
    printf '{"text":"󰚰 %s","tooltip":"%s update(s) available\\nClick to upgrade"}\n' "$count" "$count"
else
    printf '{"text":"","tooltip":"System up to date"}\n'
fi
