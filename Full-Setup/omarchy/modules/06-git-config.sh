#!/usr/bin/env bash
#
# Git identity (asked interactively rather than hardcoded) plus an ed25519
# SSH key for GitHub, tagged with that same email, plus the GitHub CLI
# (gh) itself, logged in. All three are idempotent: re-running this
# script won't re-prompt, regenerate a key, or re-auth if already done.
#
MODULE_DESC="Git identity + SSH key + GitHub CLI"

module_step() {
  pac_install git openssh github-cli || return 1

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

  if gh auth status &>/dev/null; then
    log "GitHub CLI already authenticated: $(gh auth status 2>&1 | grep -o 'as [^ ]*' | head -1)"
  elif [ ! -t 0 ]; then
    warn "Not running interactively — skipping 'gh auth login'."
    warn "Run it yourself later: gh auth login"
  else
    log "Logging in to the GitHub CLI..."
    gh auth login || warn "gh auth login failed or was cancelled — you can retry any time with: gh auth login"
  fi

  return 0
}
