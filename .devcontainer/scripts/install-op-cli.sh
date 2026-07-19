#!/usr/bin/env bash
# Install 1Password CLI from the official apt repository (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/apt.sh
source "${SCRIPT_DIR}/lib/apt.sh"

log() { printf '[install-op-cli] %s\n' "$*"; }

if cmd_exists op; then
  log "1Password CLI already installed: $(op --version 2>/dev/null || echo unknown)"
  exit 0
fi

if apt_pkg_installed 1password-cli; then
  log "1Password CLI package already installed: $(op --version 2>/dev/null || echo unknown)"
  exit 0
fi

log "Installing 1Password CLI..."

if [ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]; then
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | apt_install gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
fi

if [ ! -f /etc/apt/sources.list.d/1password.list ]; then
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
    | apt_install tee /etc/apt/sources.list.d/1password.list >/dev/null
fi

install_apt_packages 1password-cli

log "1Password CLI installed: $(op --version 2>/dev/null || echo unknown)"
