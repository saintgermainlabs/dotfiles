#!/usr/bin/env bash
# Ensure 1Password CLI is installed and authenticated (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/op-auth.sh
source "${SCRIPT_DIR}/lib/op-auth.sh"

log() { printf '[authenticate-op] %s\n' "$*"; }
die() { printf '[authenticate-op] ERROR: %s\n' "$*" >&2; exit 1; }

bash "${SCRIPT_DIR}/install-op-cli.sh"

if op_app_integration_enabled; then
  if op_agent_socket_ready; then
    log "Using 1Password app integration (agent socket mounted)"
  else
    die "1Password app integration enabled but ~/.1password/agent.sock not found.
Rebuild the devcontainer after enabling CLI integration on the host."
  fi
elif [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  log "Using OP_SERVICE_ACCOUNT_TOKEN for service account auth"
elif op whoami >/dev/null 2>&1; then
  log "Already authenticated via op session"
else
  die "1Password is not authenticated.
Set OP_SERVICE_ACCOUNT_TOKEN before bootstrap, or enable 1Password desktop CLI integration."
fi

if ! op_can_access_vault; then
  die "1Password CLI is installed but authentication failed.
Check OP_SERVICE_ACCOUNT_TOKEN, vault access, or app integration on the host."
fi

log "Authenticated via $(op_auth_summary)"
