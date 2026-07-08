#!/usr/bin/env bash
#
# Shared helpers sourced once by setup.sh and used by every module.
# Not meant to be executed directly.
#

# ---------------------------------------------------------------------------
# Color setup — respects NO_COLOR (https://no-color.org) and falls back to
# plain text when stdout isn't a terminal (e.g. piped into a log file) or
# the terminal doesn't support enough colors.
# ---------------------------------------------------------------------------
_supports_color() {
  [ -t 1 ] || return 1
  [ -z "${NO_COLOR:-}" ] || return 1
  command -v tput &>/dev/null || return 1
  [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]
}

if _supports_color; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[38;5;203m'
  C_GREEN=$'\033[38;5;114m'
  C_YELLOW=$'\033[38;5;221m'
  C_CYAN=$'\033[38;5;80m'
  C_MAGENTA=$'\033[38;5;176m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_CYAN='' C_MAGENTA=''
fi

log()  { echo -e "\n${C_BOLD}${C_GREEN}➜${C_RESET} ${C_BOLD}$*${C_RESET}"; }
warn() { echo -e "${C_BOLD}${C_YELLOW}⚠${C_RESET}  ${C_YELLOW}$*${C_RESET}"; }
err()  { echo -e "${C_BOLD}${C_RED}✖${C_RESET}  ${C_RED}$*${C_RESET}"; }
ok()   { echo -e "${C_BOLD}${C_GREEN}✓${C_RESET}  ${C_GREEN}$*${C_RESET}"; }

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

# ---------------------------------------------------------------------------
# Terminal UI: banner + boxed summary. Purely cosmetic — safe to ignore if
# you're grepping logs, since box-drawing degrades gracefully to plain text
# lines when NO_COLOR is set or output isn't a terminal (colors drop out,
# the unicode border characters remain but stay readable).
# ---------------------------------------------------------------------------
_box_width=56

_box_border() { printf '─%.0s' $(seq 1 "$_box_width"); }

# _box_line "text" "color-code"
# Centers `text` inside a box of width $_box_width using printf's own
# character counting, so it stays correct regardless of text length.
_box_line() {
  local text="$1" color="$2"
  local pad=$(( _box_width - ${#text} ))
  (( pad < 0 )) && pad=0
  local pad_left=$(( pad / 2 ))
  local pad_right=$(( pad - pad_left ))
  printf "%b│%b%*s%s%*s%b│%b\n" \
    "$color" "$C_RESET" "$pad_left" "" "$text" "$pad_right" "" "$color" "$C_RESET"
}

banner() {
  echo
  echo -e "${C_MAGENTA}╭$(_box_border)╮${C_RESET}"
  _box_line "OMARCHY SETUP" "${C_BOLD}${C_CYAN}"
  echo -e "${C_MAGENTA}╰$(_box_border)╯${C_RESET}"
  echo -e "${C_DIM}  Arch + Hyprland, now with a side of Niri${C_RESET}"
}

# summary_box "color" "line one" "line two" ...
summary_box() {
  local color="$1"; shift
  echo -e "${color}╭$(_box_border)╮${C_RESET}"
  local line
  for line in "$@"; do
    _box_line "$line" "$color"
  done
  echo -e "${color}╰$(_box_border)╯${C_RESET}"
}

format_duration() {
  local total="$1" m s
  m=$(( total / 60 ))
  s=$(( total % 60 ))
  if [ "$m" -gt 0 ]; then
    printf '%dm %ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}
