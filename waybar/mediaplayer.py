#!/usr/bin/env python3
import subprocess
import json
import sys
import time

def get_playerctl_info():
    try:
        # Get status
        status = subprocess.check_output(["playerctl", "status"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        # Get metadata
        metadata = subprocess.check_output(["playerctl", "metadata", "--format", "{{title}}"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
        return status, metadata
    except Exception:
        return "Stopped", ""

while True:
    status, metadata = get_playerctl_info()
    
    if status == "Playing":
        # Static music icon + metadata (truncated if too long to prevent waybar layout issues)
        display_text = metadata
        if len(display_text) > 35:
            display_text = display_text[:32] + "..."
        text = f"󰎆  {display_text}"
    elif status == "Paused":
        display_text = metadata
        if len(display_text) > 35:
            display_text = display_text[:32] + "..."
        text = f"󰏤  {display_text}"
    else:
        # Empty when stopped
        text = ""

    data = {
        "text": text,
        "tooltip": metadata if metadata else "No music playing",
        "class": status.lower(),
        "alt": status
    }
    
    sys.stdout.write(json.dumps(data) + "\n")
    sys.stdout.flush()
    
    # 1.0s interval when playing is responsive enough without consuming CPU like high-speed animation loops
    time.sleep(1.0 if status == "Playing" else 2.0)
