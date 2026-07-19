#!/usr/bin/env bash
# Install primordial apt packages and CLI tooling (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/apt.sh
source "${SCRIPT_DIR}/lib/apt.sh"

log() { printf '[install-primordial] %s\n' "$*"; }

PRIMORDIAL_APT_PACKAGES=(
  openssh-client
  rsync
  jq
  curl
  wget
  dnsutils
  iputils-ping
  netcat-openbsd
  htop
  vim
  ca-certificates
  gnupg
  restic
  age
  git
  sudo
  python3
  util-linux
)

main() {
  log "Checking primordial apt packages..."
  install_apt_packages "${PRIMORDIAL_APT_PACKAGES[@]}"

  log "Checking 1Password CLI..."
  bash "${SCRIPT_DIR}/install-op-cli.sh"

  log "Checking age..."
  bash "${SCRIPT_DIR}/install-age.sh"

  log "Primordial package install complete."
}

main "$@"
