#!/usr/bin/env bash
# Ensure 1Password CLI is installed and authenticated (idempotent).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[authenticate-op] %s\n' "$*"; }
die() { printf '[authenticate-op] ERROR: %s\n' "$*" >&2; exit 1; }

bash "${SCRIPT_DIR}/install-op-cli.sh"

if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  log "Using OP_SERVICE_ACCOUNT_TOKEN for service account auth"
elif op whoami >/dev/null 2>&1; then
  log "Already authenticated via app integration"
else
  die "1Password is not authenticated.
Set OP_SERVICE_ACCOUNT_TOKEN before bootstrap, or enable 1Password desktop CLI integration."
fi

if ! op whoami >/dev/null 2>&1; then
  die "1Password CLI is installed but authentication failed.
Check OP_SERVICE_ACCOUNT_TOKEN and vault access."
fi

log "Authenticated: $(op whoami 2>/dev/null | head -1)"
