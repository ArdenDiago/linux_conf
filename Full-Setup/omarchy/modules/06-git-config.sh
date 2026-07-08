#!/usr/bin/env bash
#
# Git identity (asked interactively rather than hardcoded) plus an ed25519
# SSH key for GitHub, tagged with that same email. Both are idempotent:
# re-running this script won't re-prompt or regenerate a key that's
# already there.
#
MODULE_DESC="Git identity + SSH key"

module_step() {
  pac_install git openssh || return 1

  local name email

  if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
    name="$(git config --global user.name)"
    email="$(git config --global user.email)"
    log "Git identity already configured: $name <$email>"
  else
    if [ ! -t 0 ]; then
      warn "Not running interactively — skipping git identity prompt."
      warn "Set it manually: git config --global user.name \"...\" && git config --global user.email \"...\""
      return 0
    fi

    read -rp "Git user.name: " name
    read -rp "Git user.email: " email

    if [ -z "$name" ] || [ -z "$email" ]; then
      warn "Name/email left blank — skipping git identity and SSH key setup."
      return 0
    fi

    git config --global user.name "$name"
    git config --global user.email "$email"
    log "Git identity set: $name <$email>"
  fi

  local key="$HOME/.ssh/id_ed25519"
  if [ -f "$key" ]; then
    log "SSH key already exists at $key, skipping."
  else
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    track_rollback "rm -f '$key' '$key.pub'"
    ssh-keygen -t ed25519 -C "$email" -f "$key" -N "" || return 1
    log "Generated a new ed25519 SSH key for $email."
  fi

  log "Public key — add this to https://github.com/settings/keys:"
  echo
  cat "$key.pub"
  echo

  if command -v wl-copy &>/dev/null; then
    wl-copy < "$key.pub" && log "Copied to clipboard."
  fi

  return 0
}
