#!/usr/bin/env bash
# Install 1Password CLI from the official apt repository (idempotent).
set -euo pipefail

if command -v op >/dev/null 2>&1; then
  echo "1Password CLI already installed: $(op --version 2>/dev/null || echo unknown)"
  exit 0
fi

echo "Installing 1Password CLI..."

apt_install() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | apt_install gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  | apt_install tee /etc/apt/sources.list.d/1password.list >/dev/null

apt_install apt-get update
apt_install apt-get install -y 1password-cli

echo "1Password CLI installed: $(op --version 2>/dev/null || echo unknown)"
