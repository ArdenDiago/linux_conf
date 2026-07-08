#!/usr/bin/env bash
#
# Shared helpers sourced once by setup.sh and used by every module.
# Not meant to be executed directly.
#

log()  { echo -e "\n\033[1;32m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[FAIL]\033[0m $*"; }

FAILED_STEPS=()

# Runs a step function. If it returns non-zero, log it and move on instead
# of aborting the whole script.
run_step() {
  local desc="$1"; shift
  if "$@"; then
    return 0
  fi
  err "Step failed: $desc — continuing with the rest of the script."
  FAILED_STEPS+=("$desc")
  return 0
}

pac_installed() { pacman -Qi "$1" &>/dev/null; }

# Installs one or more official-repo packages via pacman. --needed makes
# this naturally idempotent: already-installed packages are skipped.
pac_install() {
  sudo pacman -S --needed --noconfirm "$@"
}

aur_installed() { pacman -Qi "$1" &>/dev/null; }

# Installs one or more AUR packages via yay. Never run yay as root/sudo —
# it escalates internally only for the pacman parts it needs.
aur_install() {
  if ! command -v yay &>/dev/null; then
    err "yay is not available — cannot install AUR package(s): $*"
    return 1
  fi
  yay -S --needed --noconfirm "$@"
}
