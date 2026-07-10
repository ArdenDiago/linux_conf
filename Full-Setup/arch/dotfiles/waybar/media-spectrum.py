#!/usr/bin/env python3
# Persistent waybar module: streams a small cava spectrum graph while
# something is playing, hides itself otherwise. Click toggles bass boost
# (state read from BOOST_STATE_FILE, written by media-boost-toggle.sh).
import json
import os
import subprocess
import sys
import time

CONFIG_DIR = os.path.dirname(os.path.realpath(__file__))
CAVA_CONFIG = os.path.join(CONFIG_DIR, "cava-spectrum.conf")
BOOST_STATE_FILE = os.path.expanduser("~/.cache/waybar-media-boost")
BARS = "▁▂▃▄▅▆▇█"

cava = None


def is_playing():
    try:
        status = subprocess.check_output(
            ["playerctl", "status"], stderr=subprocess.DEVNULL, timeout=1
        ).decode().strip()
        return status == "Playing"
    except Exception:
        return False


def track_title():
    try:
        return subprocess.check_output(
            ["playerctl", "metadata", "title"], stderr=subprocess.DEVNULL, timeout=1
        ).decode().strip()
    except Exception:
        return ""


def is_boosted():
    return os.path.exists(BOOST_STATE_FILE)


def render(values):
    return "".join(BARS[max(0, min(int(v), 7))] for v in values)


def emit(data):
    sys.stdout.write(json.dumps(data) + "\n")
    sys.stdout.flush()


def idle():
    emit({"text": "", "class": "idle", "tooltip": "No media playing"})


def stop_cava():
    global cava
    if cava is not None:
        cava.terminate()
        try:
            cava.wait(timeout=1)
        except Exception:
            cava.kill()
        cava = None


def start_cava():
    global cava
    cava = subprocess.Popen(
        ["cava", "-p", CAVA_CONFIG],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )


def main():
    try:
        while True:
            if is_playing():
                if cava is None:
                    start_cava()
                line = cava.stdout.readline()
                if not line:
                    stop_cava()
                    idle()
                    time.sleep(0.5)
                    continue
                values = [int(v) for v in line.strip().rstrip(";").split(";") if v != ""]
                if not values:
                    continue
                boosted = is_boosted()
                title = track_title()
                tooltip = "Bass boost: {}\nClick to toggle".format("ON" if boosted else "OFF")
                if title:
                    tooltip = "{}\n\n{}".format(title, tooltip)
                emit({
                    "text": render(values),
                    "class": "boosted" if boosted else "playing",
                    "tooltip": tooltip,
                })
            else:
                stop_cava()
                idle()
                time.sleep(1)
    finally:
        stop_cava()


if __name__ == "__main__":
    main()
