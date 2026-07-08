#!/usr/bin/env bash
#
# Antigravity ships only as a tarball from Google's CDN — no Arch package,
# so this mirrors the Pop!_OS install method exactly.
#
MODULE_DESC="Antigravity IDE"

module_step() {
  if [ -x "$HOME/.local/bin/antigravity" ]; then
    log "Antigravity already installed, skipping."
    return 0
  fi
  log "Installing Antigravity IDE"
  local url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz"
  local tarball="$TMPDIR/antigravity.tar.gz"
  curl --retry 5 --retry-delay 3 --retry-all-errors -C - -fSL "$url" -o "$tarball" || return 1
  mkdir -p "$HOME/.local/antigravity"
  track_rollback "rm -rf '$HOME/.local/antigravity' '$HOME/.local/bin/antigravity'"
  tar -xzf "$tarball" -C "$HOME/.local/antigravity" --strip-components=1 || return 1
  ensure_on_path antigravity "$HOME/.local/antigravity/antigravity"
  return 0
}
