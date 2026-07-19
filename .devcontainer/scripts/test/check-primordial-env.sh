#!/usr/bin/env bash
# Test: primordial age-encrypted env decrypts and exports OP token.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/op-auth.sh
source "${SCRIPT_DIR}/lib/op-auth.sh"

log() { printf '[test-primordial-env] %s\n' "$*"; }
die() { printf '[test-primordial-env] FAIL: %s\n' "$*" >&2; exit 1; }

ENCRYPTED="${PRIMORDIAL_ENV_AGE:-/opt/primordial/secrets/primordial.env.age}"
ENV_FILE="${PRIMORDIAL_ENV_FILE:-/var/lib/primordial/primordial.env}"

if [ ! -f "${ENCRYPTED}" ]; then
  die "Missing ${ENCRYPTED} — commit primordial.env.age and rebuild/pull the image"
fi

bash /opt/primordial/scripts/decrypt-primordial-env.sh

if [ ! -f "${ENV_FILE}" ]; then
  die "Decrypted env not written to ${ENV_FILE}"
fi

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  if op_app_integration_enabled && op_can_access_vault; then
    log "OK: app integration active (no OP_SERVICE_ACCOUNT_TOKEN in primordial env)"
    log "OK: decrypted ${ENV_FILE}"
    exit 0
  fi
  die "OP_SERVICE_ACCOUNT_TOKEN not exported after sourcing ${ENV_FILE}"
fi

if ! op whoami >/dev/null 2>&1; then
  die "op whoami failed after sourcing decrypted primordial env"
fi

log "OK: decrypted ${ENV_FILE}"
log "OK: OP_SERVICE_ACCOUNT_TOKEN is set"
log "OK: op authenticated as $(op whoami 2>/dev/null | head -1)"
