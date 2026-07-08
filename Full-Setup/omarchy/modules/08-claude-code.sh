#!/usr/bin/env bash
#
# Official cross-distro installer — no Arch package exists for this.
#
MODULE_DESC="Claude Code"

module_step() {
  if command -v claude &>/dev/null || [ -x "$HOME/.local/bin/claude" ]; then
    log "Claude Code already installed, skipping."
    return 0
  fi
  log "Installing Claude Code"
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL https://claude.ai/install.sh | bash
}
