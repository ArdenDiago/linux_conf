#!/usr/bin/env bash
#
# Pop!_OS Setup Script — with Niri Window Manager
# Modular, idempotent, resilient: each step is isolated so one failure
# (bad PPA, network blip, changed URL, etc.) logs a warning and the script
# keeps going instead of dying halfway through.
#
set -uo pipefail
IFS=$'\n\t'

log()  { echo -e "\n\033[1;32m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[FAIL]\033[0m $*"; }

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

FAILED_STEPS=()

# Runs a step function. If it returns non-zero, log it and move on instead
# of aborting the whole script.
run_step() {
  local desc="$1"; shift
  if "$@"; then
    return 0
  else
    err "Step failed: $desc — continuing with the rest of the script."
    FAILED_STEPS+=("$desc")
    return 0
  fi
}

# ---------------------------------------------------------------------------
# 0. Preconditions
# ---------------------------------------------------------------------------
step_preconditions() {
  # add-apt-repository needs this; Pop!_OS usually has it, but don't assume.
  if ! command -v add-apt-repository &>/dev/null; then
    sudo apt update || true
    sudo apt install -y software-properties-common || return 1
  fi
  return 0
}

# Self-heal: remove any known-broken PPA left over from a previous run before
# the very first apt update, so it can't block every subsequent apt call.
step_cleanup_stale_ppas() {
  if grep -rq "avengemedia.*dms" /etc/apt/sources.list.d/ 2>/dev/null; then
    if ! apt-cache policy dms 2>/dev/null | grep -q "Candidate:"; then
      warn "Removing a stale/broken dms PPA entry left over from a previous run."
      sudo add-apt-repository -y --remove ppa:avengemedia/dms 2>/dev/null || true
      sudo rm -f /etc/apt/sources.list.d/avengemedia-ubuntu-dms-*.sources 2>/dev/null || true
      sudo rm -f /etc/apt/sources.list.d/avengemedia-ubuntu-dms-*.list 2>/dev/null || true
    fi
  fi
  return 0
}

# ---------------------------------------------------------------------------
# 1. System Maintenance
# ---------------------------------------------------------------------------
step_system_update() {
  sudo apt update || warn "apt update reported an issue with at least one repo; continuing with what succeeded."
  sudo apt full-upgrade -y || return 1
  sudo apt autoremove -y || true
  sudo apt clean || true
  return 0
}

# ---------------------------------------------------------------------------
# 2. Package Managers: Snap + Flatpak
# ---------------------------------------------------------------------------
step_snap_flatpak() {
  if ! command -v snap &>/dev/null; then
    sudo apt install -y snapd || return 1
    # snapd needs a moment to seed itself right after a fresh install;
    # without this, the first snap install can fail with "not fully seeded".
    log "Waiting for snapd to finish seeding..."
    sudo snap wait system seed.loaded || sleep 10
  fi

  if ! command -v flatpak &>/dev/null; then
    sudo apt install -y flatpak || return 1
  fi
  if ! sudo flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || return 1
  fi
  # Confirm the remote actually has usable metadata (not just registered)
  if ! sudo flatpak remote-info flathub org.flatpak.Platform &>/dev/null; then
    warn "flathub added but metadata pull failed — retrying."
    sudo flatpak update --appstream flathub || true
  fi
  return 0
}

# ---------------------------------------------------------------------------
# 3. Core Applications
# ---------------------------------------------------------------------------
step_core_apps() {
  local ok=0
  for pkg in vlc alacritty tmux btop; do
    if dpkg -s "$pkg" &>/dev/null; then
      log "$pkg already installed, skipping."
    else
      sudo apt install -y "$pkg" || { warn "$pkg install failed."; ok=1; }
    fi
  done
  return $ok
}

step_android_studio() {
  if snap list android-studio &>/dev/null; then
    log "android-studio already installed, skipping."
    return 0
  fi
  sudo snap install android-studio --classic
}

step_docker() {
  if command -v docker &>/dev/null; then
    log "Docker already installed, skipping."
    return 0
  fi
  log "Installing Docker"
  sudo install -m 0755 -d /etc/apt/keyrings || return 1
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || return 1
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update || warn "apt update reported an issue with at least one repo; continuing."
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
  sudo usermod -aG docker "$USER"
  warn "Log out/in (or run 'newgrp docker') for docker group membership to take effect."
  return 0
}

step_ollama() {
  if command -v ollama &>/dev/null; then
    log "Ollama already installed, skipping."
    return 0
  fi
  log "Installing Ollama"
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL https://ollama.com/install.sh | sh
}

# ---------------------------------------------------------------------------
# 4. Developer Tooling & Configuration
# ---------------------------------------------------------------------------
step_git() {
  if dpkg -s git &>/dev/null; then
    log "git already installed, skipping."
  else
    sudo apt install -y git || return 1
  fi
  git config --global user.name "Arden Diago"
  git config --global user.email "diagoarden@gmail.com"
  return 0
}

step_add_local_bin_to_path() {
  if ! grep -q '$HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    log "Added ~/.local/bin to PATH in ~/.bashrc (run 'source ~/.bashrc' or open a new terminal)."
  else
    log "~/.local/bin already on PATH in ~/.bashrc."
  fi
  return 0
}

step_claude_code() {
  if command -v claude &>/dev/null || [ -x "$HOME/.local/bin/claude" ]; then
    log "Claude Code already installed, skipping."
    return 0
  fi
  log "Installing Claude Code"
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL https://claude.ai/install.sh | bash
}

step_antigravity() {
  if [ -x "$HOME/.local/bin/antigravity" ]; then
    log "Antigravity already installed, skipping."
    return 0
  fi
  log "Installing Antigravity IDE"
  local url="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz"
  local tarball="$TMPDIR/antigravity.tar.gz"
  curl --retry 5 --retry-delay 3 --retry-all-errors -C - -fSL "$url" -o "$tarball" || return 1
  mkdir -p "$HOME/.local/antigravity"
  tar -xzf "$tarball" -C "$HOME/.local/antigravity" --strip-components=1 || return 1
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/antigravity/antigravity" "$HOME/.local/bin/antigravity"
  log "antigravity linked into ~/.local/bin."
  return 0
}

step_lazyvim() {
  if [ -d "$HOME/.config/nvim" ]; then
    log "~/.config/nvim already exists, skipping LazyVim clone."
    return 0
  fi
  sudo apt install -y neovim ripgrep fd-find || return 1
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" || return 1
  rm -rf "$HOME/.config/nvim/.git"
  return 0
}

step_vscode() {
  if dpkg -s code &>/dev/null; then
    log "VS Code already installed, skipping."
    return 0
  fi
  log "Installing VS Code"
  local deb="$TMPDIR/vscode.deb"
  curl --retry 5 --retry-delay 3 --retry-all-errors -C - -fSL \
    "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o "$deb" || return 1
  sudo apt install -y "$deb"
}

ensure_flathub_ready() {
  if ! sudo flatpak remote-info flathub org.flatpak.Platform &>/dev/null; then
    warn "flathub remote has no usable refs — re-adding and refreshing."
    sudo flatpak remote-delete flathub --force 2>/dev/null || true
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || return 1
    sudo flatpak update --appstream flathub || return 1
  fi
  return 0
}

step_obsidian() {
  log "Installing Obsidian"
  ensure_flathub_ready || return 1

  if sudo flatpak list | grep -q md.obsidian.Obsidian; then
    log "Obsidian already installed, skipping."
  else
    if ! sudo flatpak install -y flathub md.obsidian.Obsidian; then
      warn "First install attempt failed, retrying after forcing a flathub refresh."
      sudo flatpak remote-delete flathub --force 2>/dev/null || true
      sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || return 1
      sudo flatpak update --appstream flathub || return 1
      sudo flatpak install -y flathub md.obsidian.Obsidian || return 1
    fi
  fi
  mkdir -p "$HOME/Documents/ObsidianVault"
  return 0
}

# ---------------------------------------------------------------------------
# 5. NVIDIA GPU Driver Verification
# ---------------------------------------------------------------------------
# Assumes Pop!_OS was installed from the NVIDIA ISO, so the proprietary driver
# and system76-driver-nvidia are already present. This step verifies that,
# makes sure it's current, and confirms the kernel modeset flag niri needs.
step_nvidia_driver() {
  if ! lspci | grep -qi nvidia; then
    log "No NVIDIA GPU detected, skipping driver checks."
    return 0
  fi

  if dpkg -s system76-driver-nvidia &>/dev/null; then
    log "system76-driver-nvidia found, checking for updates"
    sudo apt install -y --only-upgrade system76-driver-nvidia || warn "Upgrade check for system76-driver-nvidia failed."
  else
    warn "NVIDIA GPU detected but system76-driver-nvidia isn't installed."
    warn "If this system was NOT installed from the NVIDIA ISO, install manually:"
    warn "  sudo apt install -y system76-driver-nvidia"
    warn "Reboot afterward before trying niri."
  fi

  if command -v nvidia-smi &>/dev/null; then
    log "Driver active: $(nvidia-smi --query-gpu=driver_version,name --format=csv,noheader 2>/dev/null || echo 'unknown')"
  else
    warn "nvidia-smi not found — driver may need a reboot to load, or isn't installed yet."
  fi

  # niri requires nvidia-drm.modeset=1. Pop!_OS defaults to systemd-boot,
  # managed via System76's kernelstub tool — there is no /etc/default/grub
  # on those systems. Handle kernelstub first, fall back to GRUB if present.
  if command -v kernelstub &>/dev/null; then
    if kernelstub -p 2>/dev/null | grep -q "nvidia-drm.modeset=1"; then
      log "Kernel modesetting (nvidia-drm.modeset=1) already set via kernelstub."
    else
      warn "nvidia-drm.modeset=1 not set — adding it via kernelstub."
      if sudo kernelstub -a "nvidia-drm.modeset=1"; then
        warn "Modeset flag added. A reboot is required for this to take effect."
      else
        warn "kernelstub failed to add the modeset flag — set it manually: sudo kernelstub -a \"nvidia-drm.modeset=1\""
      fi
    fi
  elif [ -f /etc/default/grub ]; then
    if grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
      log "Kernel modesetting (nvidia-drm.modeset=1) already set."
    else
      warn "nvidia-drm.modeset=1 not found in /etc/default/grub — adding it."
      sudo cp /etc/default/grub /etc/default/grub.bak
      sudo sed -i \
        's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' \
        /etc/default/grub
      if sudo update-grub; then
        warn "Modeset flag added. A reboot is required for this to take effect."
      else
        warn "update-grub failed — restoring backup grub config."
        sudo cp /etc/default/grub.bak /etc/default/grub
      fi
    fi
  else
    warn "Neither kernelstub nor /etc/default/grub found — set nvidia-drm.modeset=1 manually for your bootloader."
  fi
  return 0
}

# ---------------------------------------------------------------------------
# 6. Niri Window Manager (scrollable-tiling Wayland compositor)
# ---------------------------------------------------------------------------
step_rust_toolchain() {
  if command -v cargo &>/dev/null; then
    log "Rust/cargo already installed, skipping."
    return 0
  fi
  log "Installing Rust toolchain via rustup (needed to build niri from source)"
  curl --retry 5 --retry-delay 3 --retry-all-errors -fsSL https://sh.rustup.rs -o "$TMPDIR/rustup-init.sh" || return 1
  sh "$TMPDIR/rustup-init.sh" -y --default-toolchain stable || return 1
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
  return 0
}

step_niri() {
  # Ubuntu/Pop!_OS 24.04 (noble) is below the Ubuntu 25.10+ / Qt 6.6+
  # requirement of the avengemedia PPAs, so niri isn't available as a .deb
  # here. Build it from source instead — niri's own documented fallback
  # for unsupported distros.
  if command -v niri &>/dev/null; then
    log "niri already installed, skipping."
  else
    if ! command -v cargo &>/dev/null; then
      warn "cargo not found — run the rust toolchain step first."
      return 1
    fi
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env" 2>/dev/null || true

    log "Installing niri build dependencies"
    sudo apt install -y \
      gcc clang pkg-config libudev-dev libgbm-dev libxkbcommon-dev \
      libegl1-mesa-dev libwayland-dev libinput-dev libdbus-1-dev \
      libsystemd-dev libseat-dev libpipewire-0.3-dev libpango1.0-dev \
      libcairo2-dev libdisplay-info-dev || return 1

    local build_dir="$TMPDIR/niri-src"
    log "Cloning niri source (this can take a minute)"
    git clone --depth 1 https://github.com/niri-wm/niri "$build_dir" || return 1

    log "Building niri (this takes several minutes on first build)"
    (cd "$build_dir" && cargo build --release --locked) || return 1

    log "Installing niri binary and session files"
    sudo install -m 755 "$build_dir/target/release/niri" /usr/local/bin/niri || return 1
    if [ -f "$build_dir/resources/niri-session" ]; then
      sudo install -m 755 "$build_dir/resources/niri-session" /usr/local/bin/niri-session
    fi
    sudo mkdir -p /usr/local/share/wayland-sessions
    if [ -f "$build_dir/resources/niri.desktop" ]; then
      sudo install -m 644 "$build_dir/resources/niri.desktop" /usr/local/share/wayland-sessions/
    fi
    if [ -f "$build_dir/resources/niri-portals.conf" ]; then
      sudo mkdir -p /usr/local/share/xdg-desktop-portal
      sudo install -m 644 "$build_dir/resources/niri-portals.conf" /usr/local/share/xdg-desktop-portal/
    fi
  fi

  # Companion software niri expects you to bring yourself: launcher,
  # notification daemon, screen-lock. xwayland-satellite handles X11 apps —
  # try apt first, fall back to cargo since it's a newer Rust tool that
  # may not be packaged for this release either.
  for pkg in fuzzel mako swaybg swaylock policykit-1-gnome; do
    if dpkg -s "$pkg" &>/dev/null; then
      log "$pkg already installed, skipping."
    else
      sudo apt install -y "$pkg" || \
        warn "$pkg not available in your repos; check the package name for your release."
    fi
  done

  if command -v xwayland-satellite &>/dev/null; then
    log "xwayland-satellite already installed, skipping."
  elif dpkg -s xwayland-satellite &>/dev/null; then
    log "xwayland-satellite already installed, skipping."
  elif sudo apt install -y xwayland-satellite 2>/dev/null; then
    log "xwayland-satellite installed via apt."
  elif command -v cargo &>/dev/null; then
    warn "xwayland-satellite not in apt for this release — building via cargo instead."
    cargo install xwayland-satellite || warn "cargo install of xwayland-satellite failed; X11 apps may not work under niri."
  else
    warn "xwayland-satellite unavailable — X11 apps may not work under niri."
  fi

  # Enable the niri user systemd service so portals/session targets start correctly.
  systemctl --user add-wants niri.service 2>/dev/null || \
    warn "Could not pre-wire niri.service; configure after first login instead."

  mkdir -p "$HOME/.config/niri"

  if lspci | grep -qi nvidia; then
    warn "There is a known niri+NVIDIA high-VRAM-usage quirk (heap reuse);"
    warn "  see the niri wiki's NVIDIA section if you see excessive VRAM use."
    warn "For hybrid graphics PRIME offload, launch apps with:"
    warn "  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>"
  fi

  log "Niri installed. Log out and select 'Niri' from your display manager's session menu to try it."
  log "If it's not listed yet, you may need to run 'sudo update-desktop-database' or reboot."
  log "No desktop shell (DMS/Waybar) was installed since DMS requires Ubuntu 25.10+;"
  log "consider installing waybar separately for a status bar: sudo apt install -y waybar"
  return 0
}

# ---------------------------------------------------------------------------
# 7. Cleanup
# ---------------------------------------------------------------------------
step_cleanup() {
  sudo apt autoremove -y || true
  sudo apt clean || true
  return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "Checking prerequisites"
run_step "preconditions" step_preconditions
run_step "cleanup stale PPAs" step_cleanup_stale_ppas

log "Updating system packages"
run_step "system update" step_system_update

log "Configuring Snap and Flatpak"
run_step "snap/flatpak setup" step_snap_flatpak

log "Installing core applications"
run_step "core applications" step_core_apps
run_step "android studio" step_android_studio
run_step "docker" step_docker
run_step "ollama" step_ollama

log "Developer Tooling & Configuration"
run_step "git" step_git
run_step "claude code" step_claude_code
run_step "PATH setup" step_add_local_bin_to_path
run_step "antigravity" step_antigravity
run_step "lazyvim" step_lazyvim
run_step "vscode" step_vscode
run_step "obsidian" step_obsidian

log "Verifying NVIDIA driver"
run_step "nvidia driver" step_nvidia_driver

log "Setting up Niri"
run_step "rust toolchain" step_rust_toolchain
run_step "niri" step_niri

log "Final cleanup"
run_step "cleanup" step_cleanup

if [ "${#FAILED_STEPS[@]}" -eq 0 ]; then
  log "Setup complete. All steps succeeded."
else
  warn "Setup finished, but these steps had issues (see [FAIL]/[WARN] above for details):"
  for s in "${FAILED_STEPS[@]}"; do
    warn "  - $s"
  done
  log "Everything else completed. Re-run this script any time — it's safe and will skip what's already done."
fi