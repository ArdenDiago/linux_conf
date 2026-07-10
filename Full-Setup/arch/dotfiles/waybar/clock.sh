#!/usr/bin/env bash
# Two-line clock for the v7 theme's custom/clock module.

time=$(date +"%I:%M %p")
date_str=$(date +"%A, %d/%m")

printf '{"text":"%s\\n%s"}\n' "$time" "$date_str"
