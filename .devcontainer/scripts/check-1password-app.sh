#!/usr/bin/env bash
# Verify 1Password app integration is ready on the host before opening local devcontainer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/op-auth.sh
source "${SCRIPT_DIR}/lib/op-auth.sh"

log() { printf '[check-1password-app] %s\n' "$*"; }
die() { printf '[check-1password-app] FAIL: %s\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
  die "Do not run this script with sudo.
It checks ${HOME}/.1password/agent.sock for the current user.
Run: bash .devcontainer/scripts/check-1password-app.sh"
fi

if ! command -v op >/dev/null 2>&1; then
  die "1Password CLI (op) not found on the host.
Install: https://developer.1password.com/docs/cli/get-started/"
fi

if [ -f "${SCRIPT_DIR}/../.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../.env"
  set +a
fi

export OP_USE_APP_INTEGRATION="${OP_USE_APP_INTEGRATION:-1}"

if ! op_agent_socket_ready; then
  die "Missing ${HOME}/.1password/agent.sock
1. Install and unlock the 1Password desktop app
2. Settings → Developer → enable 'Integrate with 1Password CLI'
3. Re-run: bash .devcontainer/scripts/check-1password-app.sh"
fi

if ! op_can_access_vault; then
  die "1Password app integration is not ready.
The agent socket exists but op cannot read vault items yet.
1. Unlock the 1Password desktop app
2. Confirm CLI integration is enabled in Settings → Developer
3. Retry: bash .devcontainer/scripts/check-1password-app.sh"
fi

log "OK: 1Password app integration ready ($(op_auth_summary))"
log "OK: agent socket at ${HOME}/.1password/agent.sock"
log "Ready for local devcontainer (no service account token needed on host)"
