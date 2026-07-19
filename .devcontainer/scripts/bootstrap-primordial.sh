#!/usr/bin/env bash
# Primordial bootstrap: probe environment and authenticate 1Password.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/load-profile.sh
source "${SCRIPT_DIR}/lib/load-profile.sh"
load_devcontainer_profile "${REPO_ROOT}" || true

log() { printf '[bootstrap-primordial] %s\n' "$*"; }

log "Starting primordial bootstrap (profile=${DEVCONTAINER_PROFILE:-unknown}, role=${DOTFILES_ROLE:-unknown})..."

bash "${SCRIPT_DIR}/verify-mounts.sh"

# op auth + age key are required before decrypting the baked-in primordial.env.age
bash "${SCRIPT_DIR}/authenticate-op.sh"
bash "${SCRIPT_DIR}/setup-age-key.sh"

# First .env: decrypt age-encrypted primordial env from the image
bash "${SCRIPT_DIR}/decrypt-primordial-env.sh"

# Re-verify op if the decrypted env supplied OP_SERVICE_ACCOUNT_TOKEN
if ! op whoami >/dev/null 2>&1 && [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  bash "${SCRIPT_DIR}/authenticate-op.sh"
fi

# Optional repo-level encrypted env → ~/.dotfiles/dot_env/.env
bash "${SCRIPT_DIR}/decrypt-env.sh"
bash "${SCRIPT_DIR}/probe-env.sh" runtime

if [ -f /var/lib/primordial/image-env.json ]; then
  log "Image probe (build-time): /var/lib/primordial/image-env.json"
fi

if [ -f /var/lib/primordial/primordial.env ]; then
  log "Primordial env: /var/lib/primordial/primordial.env"
fi

log "Runtime probe: /var/lib/primordial/env.json"
log "Primordial bootstrap complete."
