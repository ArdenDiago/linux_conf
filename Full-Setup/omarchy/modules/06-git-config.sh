#!/usr/bin/env bash
#
# Git itself plus the same global identity used in the Pop!_OS setup.sh.
#
MODULE_DESC="Git"

module_step() {
  pac_install git || return 1
  git config --global user.name "Arden Diago"
  git config --global user.email "diagoarden@gmail.com"
  return 0
}
