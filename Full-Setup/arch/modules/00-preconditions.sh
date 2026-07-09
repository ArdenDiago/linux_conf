#!/usr/bin/env bash
#
# Sanity checks and one-time bootstrapping that every later module relies
# on: a synced package database, base-devel/git for building AUR packages,
# and the yay AUR helper itself. Vanilla Arch doesn't ship yay, so this
# bootstraps it from the AUR the first time this script runs.
#
MODULE_DESC="Preconditions"

module_step() {
  # A pacman transaction killed mid-run (crash, power loss, Ctrl-C) can
  # leave a stale lock file that blocks every future pacman call. Only
  # remove it if no pacman process is actually running.
  if [ -f /var/lib/pacman/db.lck ] && ! pgrep -x pacman &>/dev/null; then
    warn "Removing a stale pacman lock file left over from an interrupted run."
    sudo rm -f /var/lib/pacman/db.lck
  fi

  sudo pacman -Sy --noconfirm || return 1
  pac_install base-devel git || return 1

  if command -v yay &>/dev/null; then
    log "yay already installed, skipping."
    return 0
  fi

  log "Bootstrapping yay (AUR helper)"
  local build_dir="$TMPDIR/yay"
  git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir" || return 1
  # makepkg refuses to run as root, and must not be invoked with sudo.
  track_rollback "sudo pacman -Rns --noconfirm yay 2>/dev/null || true"
  (cd "$build_dir" && makepkg -si --noconfirm) || return 1
  return 0
}
