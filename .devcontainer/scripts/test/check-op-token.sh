#!/usr/bin/env bash
# Test 1: OP service account token is available and authenticates op.
set -euo pipefail

log() { printf '[test-op-token] %s\n' "$*"; }
die() { printf '[test-op-token] FAIL: %s\n' "$*" >&2; exit 1; }

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  die "OP_SERVICE_ACCOUNT_TOKEN is not set.
Supply at container runtime, not at docker build time:
  docker run -e OP_SERVICE_ACCOUNT_TOKEN ..."
fi

if ! command -v op >/dev/null 2>&1; then
  die "op CLI is not installed in this image"
fi

if ! op whoami >/dev/null 2>&1; then
  die "op whoami failed — token is set but invalid or lacks vault access"
fi

log "OK: OP_SERVICE_ACCOUNT_TOKEN is set"
log "OK: op authenticated as $(op whoami 2>/dev/null | head -1)"
