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

banner

shopt -s nullglob
module_files=("$MODULES_DIR"/*.sh)
shopt -u nullglob

if [ "${#module_files[@]}" -eq 0 ]; then
  err "No modules found in $MODULES_DIR — nothing to do."
  exit 1
fi

total_modules="${#module_files[@]}"
idx=0
run_start="$SECONDS"

for module in "${module_files[@]}"; do
  idx=$((idx + 1))

  # shellcheck source=/dev/null
  source "$module"

  if ! declare -f module_step &>/dev/null; then
    warn "Skipping $(basename "$module") — it doesn't define module_step()."
    continue
  fi

  step_name="${MODULE_DESC:-$(basename "$module")}"
  echo -e "\n${C_DIM}[$idx/$total_modules]${C_RESET} ${C_BOLD}${C_CYAN}${step_name}${C_RESET}"

  before_failures="${#FAILED_STEPS[@]}"
  step_start="$SECONDS"
  run_step "$step_name" module_step
  step_elapsed=$(( SECONDS - step_start ))

  if [ "${#FAILED_STEPS[@]}" -eq "$before_failures" ]; then
    ok "${step_name} ${C_DIM}($(format_duration "$step_elapsed"))${C_RESET}"
  fi

  # Unset so a module that forgets to define one of these can't silently
  # reuse the previous module's leftovers.
  unset -f module_step
  unset MODULE_DESC
done

total_elapsed=$(( SECONDS - run_start ))
succeeded=$(( total_modules - ${#FAILED_STEPS[@]} ))

echo
if [ "${#FAILED_STEPS[@]}" -eq 0 ]; then
  summary_box "${C_BOLD}${C_GREEN}" \
    "✓ All $total_modules/$total_modules steps completed" \
    "Total time: $(format_duration "$total_elapsed")"
else
  summary_lines=("⚠ $succeeded/$total_modules steps completed" "Total time: $(format_duration "$total_elapsed")" "" "Needs another look:")
  for s in "${FAILED_STEPS[@]}"; do
    summary_lines+=("  ✖ $s")
  done
  summary_box "${C_BOLD}${C_YELLOW}" "${summary_lines[@]}"
  echo -e "${C_DIM}Re-run this script any time — it's safe and will skip what's already done.${C_RESET}"
fi
