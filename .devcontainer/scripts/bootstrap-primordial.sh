#!/usr/bin/env bash
# Primordial bootstrap: probe environment and authenticate 1Password.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[bootstrap-primordial] %s\n' "$*"; }

log "Starting primordial bootstrap..."

bash "${SCRIPT_DIR}/verify-mounts.sh"
bash "${SCRIPT_DIR}/authenticate-op.sh"
bash "${SCRIPT_DIR}/setup-age-key.sh"
bash "${SCRIPT_DIR}/decrypt-env.sh"
bash "${SCRIPT_DIR}/probe-env.sh" runtime

if [ -f /var/lib/primordial/image-env.json ]; then
  log "Image probe (build-time): /var/lib/primordial/image-env.json"
fi

log "Runtime probe: /var/lib/primordial/env.json"
log "Primordial bootstrap complete."
