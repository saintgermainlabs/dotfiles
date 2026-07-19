#!/usr/bin/env bash
# Install age from apt if not already present (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/apt.sh
source "${SCRIPT_DIR}/lib/apt.sh"

log() { printf '[install-age] %s\n' "$*"; }

if cmd_exists age || apt_pkg_installed age; then
  log "age already installed: $(age --version 2>/dev/null || echo unknown)"
  exit 0
fi

log "Installing age..."
install_apt_packages age

log "age installed: $(age --version 2>/dev/null || echo unknown)"
