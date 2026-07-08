#!/usr/bin/env bash
#
# Omarchy Setup Script — with Niri as an optional window manager alongside
# Hyprland.
#
# Modular & dynamic: every file in modules/ is a self-contained step that
# defines MODULE_DESC and a module_step() function. This script just sources
# them in filename order and runs each one — drop in a new NN-name.sh file
# and it's picked up automatically, no edits needed here.
#
# Resilient: one module failing (AUR outage, network blip, changed URL,
# etc.) logs a warning and the script keeps going instead of dying halfway
# through. Safe to re-run any time — every module skips work already done.
#
# Usage: ./setup.sh
#
set -uo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

if ! command -v pacman &>/dev/null; then
  err "pacman not found — this script is for Omarchy/Arch Linux only."
  exit 1
fi

TMPDIR="$(mktemp -d)"
export TMPDIR
trap 'rm -rf "$TMPDIR"' EXIT

log "Running Omarchy setup"

shopt -s nullglob
module_files=("$MODULES_DIR"/*.sh)
shopt -u nullglob

if [ "${#module_files[@]}" -eq 0 ]; then
  err "No modules found in $MODULES_DIR — nothing to do."
  exit 1
fi

for module in "${module_files[@]}"; do
  # shellcheck source=/dev/null
  source "$module"

  if ! declare -f module_step &>/dev/null; then
    warn "Skipping $(basename "$module") — it doesn't define module_step()."
    continue
  fi

  step_name="${MODULE_DESC:-$(basename "$module")}"
  log "$step_name"
  run_step "$step_name" module_step

  # Unset so a module that forgets to define one of these can't silently
  # reuse the previous module's leftovers.
  unset -f module_step
  unset MODULE_DESC
done

echo
if [ "${#FAILED_STEPS[@]}" -eq 0 ]; then
  log "Setup complete. All steps succeeded."
else
  warn "Setup finished, but these steps had issues (see [FAIL]/[WARN] above for details):"
  for s in "${FAILED_STEPS[@]}"; do
    warn "  - $s"
  done
  log "Everything else completed. Re-run this script any time — it's safe and will skip what's already done."
fi
