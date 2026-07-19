#!/usr/bin/env bash
# Ensure age is installed and ~/.config/age/key.txt exists (fetch from 1Password).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGE_DIR="${AGE_DIR:-${HOME}/.config/age}"
AGE_KEY="${AGE_KEY:-${AGE_DIR}/key.txt}"
OP_ITEM_REF="${OP_AGE_KEY_REF:-op://Security Keys/chezmoi age key/key.txt}"

log() { printf '[setup-age-key] %s\n' "$*"; }
die() { printf '[setup-age-key] ERROR: %s\n' "$*" >&2; exit 1; }

ensure_age() {
  if command -v age >/dev/null 2>&1; then
    log "age already installed: $(age --version 2>/dev/null || echo unknown)"
    return 0
  fi

  log "Installing age..."
  if [ "$(id -u)" -eq 0 ]; then
    apt-get update
    apt-get install -y age
  else
    sudo apt-get update
    sudo apt-get install -y age
  fi
}

if [ -f "${AGE_KEY}" ]; then
  log "age identity already exists at ${AGE_KEY}"
  exit 0
fi

ensure_age

if ! command -v op >/dev/null 2>&1; then
  bash "${SCRIPT_DIR}/install-op-cli.sh"
fi

if ! op whoami >/dev/null 2>&1; then
  die "1Password is not authenticated; run authenticate-op.sh first."
fi

mkdir -p "${AGE_DIR}"
chmod 700 "${AGE_DIR}"

log "Retrieving age key from 1Password..."
op read "${OP_ITEM_REF}" > "${AGE_KEY}"
chmod 600 "${AGE_KEY}"

log "age identity installed at ${AGE_KEY}"
