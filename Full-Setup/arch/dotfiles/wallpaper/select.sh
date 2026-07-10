#!/usr/bin/env bash
# Wallpaper picker — bound to Super+W (Hyprland) / Mod+W (niri). Shows
# actual image previews (no filenames) for everything in
# ~/Pictures/Wallpapers via fuzzel's icon protocol, and applies whatever
# gets picked immediately through swaybg, remembering it in
# ~/.config/wallpaper/current so restore.sh brings it back on next login.
#
# fuzzel's icon loader only supports PNG/SVG, not JPEG (confirmed against
# `fuzzel --version`, which reports "+png +svg", no "+jpeg") — so each
# wallpaper gets a small PNG thumbnail cached under ~/.cache/wallpaper-
# thumbs/, regenerated only when missing or older than the source image.
# Selection is tracked with fuzzel's --index (0-based) rather than by
# text, since every entry's label is intentionally just a blank space —
# text-matching identical blank labels back to a specific file wouldn't
# work.

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
STATE_DIR="$HOME/.config/wallpaper"
STATE_FILE="$STATE_DIR/current"

mkdir -p "$WALLPAPER_DIR" "$THUMB_DIR" "$STATE_DIR"

mapfile -t files < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) \
    | sort)

if [ "${#files[@]}" -eq 0 ]; then
    fuzzel --dmenu --prompt-only "No wallpapers in $WALLPAPER_DIR — add some and try again" >/dev/null
    exit 0
fi

menu=""
for f in "${files[@]}"; do
    thumb="$THUMB_DIR/$(basename "$f").png"
    if [ ! -f "$thumb" ] || [ "$f" -nt "$thumb" ]; then
        magick "$f" -resize 320x180^ -gravity center -extent 320x180 "$thumb" 2>/dev/null
    fi
    [ -f "$thumb" ] || thumb="$f"
    menu+=" \0icon\x1f${thumb}\n"
done

index="$(printf '%b' "$menu" | fuzzel --dmenu --index --prompt " " --line-height=120 --lines=6)"
[ -z "$index" ] && exit 0

full_path="${files[$index]}"
[ -f "$full_path" ] || exit 0

pkill -x swaybg 2>/dev/null
setsid swaybg -i "$full_path" -m fill >/dev/null 2>&1 &
disown

printf '%s' "$full_path" > "$STATE_FILE"
