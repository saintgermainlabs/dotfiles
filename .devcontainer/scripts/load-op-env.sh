#!/usr/bin/env bash
# Load .devcontainer/.env and resolve op:// references on the host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROFILE_RUNTIME="${DEVCONTAINER_PROFILE_RUNTIME:-${DEVCONTAINER_DIR}/.profile.runtime}"
# shellcheck source=lib/op-auth.sh
source "${SCRIPT_DIR}/lib/op-auth.sh"
ENV_FILE="${DEVCONTAINER_OP_ENV:-${DEVCONTAINER_DIR}/.env}"
RUNTIME_ENV="${DEVCONTAINER_RUNTIME_ENV:-${DEVCONTAINER_DIR}/.env.runtime}"

log() { printf '[load-op-env] %s\n' "$*"; }
warn() { printf '[load-op-env] WARN: %s\n' "$*" >&2; }

if [ -f "${PROFILE_RUNTIME}" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${PROFILE_RUNTIME}"
  set +a
  log "Loaded ${PROFILE_RUNTIME}"
fi

load_dotenv() {
  if [ ! -f "${ENV_FILE}" ]; then
    return 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  log "Loaded ${ENV_FILE}"
  return 0
}

resolve_ref() {
  local ref_var="$1"
  local target_var="$2"
  local ref="${!ref_var:-}"

  if [ -n "${!target_var:-}" ]; then
    return 0
  fi

  if [ -z "${ref}" ]; then
    return 0
  fi

  if [[ "${ref}" != op://* ]]; then
    export "${target_var}=${ref}"
    return 0
  fi

  if ! command -v op >/dev/null 2>&1; then
    warn "op CLI not found; cannot resolve ${ref_var}=${ref}"
    return 1
  fi

  if ! op whoami >/dev/null 2>&1; then
    if op_app_integration_enabled && op_agent_socket_ready; then
      local ref="${OP_AGE_KEY_REF:-op://Security Keys/chezmoi age key/key.txt}"
      if op read "${ref}" >/dev/null 2>&1; then
        export "${target_var}=$(op read "${ref}")"
        log "Resolved ${target_var} from ${ref_var} (app integration)"
        return 0
      fi
    fi
    warn "op is not authenticated; cannot resolve ${ref_var}=${ref}"
    return 1
  fi

  export "${target_var}=$(op read "${ref}")"
  log "Resolved ${target_var} from ${ref_var}"
}

write_runtime_env() {
  local out="$1"
  shift
  local -a vars=("$@")
  : >"${out}"
  chmod 600 "${out}"
  local name
  for name in "${vars[@]}"; do
    if [ -n "${!name:-}" ]; then
      printf '%s=%q\n' "${name}" "${!name}" >>"${out}"
    fi
  done
}

declare -a RESOLVED_VARS=(
  OP_SERVICE_ACCOUNT_TOKEN
  TAILSCALE_AUTHKEY
  COOLIFY_TOKEN
  COOLIFY_URL
  COOLIFY_DOCKER_HOST
  DOZZLE_HOST
  DOZZLE_PORT
  DOZZLE_USER
  DOZZLE_PASS
)

if ! load_dotenv; then
  warn "No ${ENV_FILE}; copy .devcontainer/.env.example to .devcontainer/.env"
fi

resolve_ref OP_SERVICE_ACCOUNT_TOKEN_REF OP_SERVICE_ACCOUNT_TOKEN || true
resolve_ref TAILSCALE_AUTHKEY_REF TAILSCALE_AUTHKEY || true
resolve_ref COOLIFY_TOKEN_REF COOLIFY_TOKEN || true
resolve_ref DOZZLE_HOST_REF DOZZLE_HOST || true
resolve_ref DOZZLE_PORT_REF DOZZLE_PORT || true
resolve_ref DOZZLE_USER_REF DOZZLE_USER || true
resolve_ref DOZZLE_PASS_REF DOZZLE_PASS || true

if [ "${WRITE_RUNTIME_ENV:-1}" = "1" ]; then
  write_runtime_env "${RUNTIME_ENV}" "${RESOLVED_VARS[@]}"
  log "Wrote ${RUNTIME_ENV}"
fi

if [ -n "${OP_USE_APP_INTEGRATION:-}" ] && [ "${OP_USE_APP_INTEGRATION}" != "0" ]; then
  if command -v op >/dev/null 2>&1 && op whoami >/dev/null 2>&1; then
    log "1Password app integration available on host (op whoami OK)"
  else
    log "Local app integration mode — OP_SERVICE_ACCOUNT_TOKEN not required on host"
  fi
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 0
  fi
  exit 0
fi

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  cat >&2 <<EOF
OP_SERVICE_ACCOUNT_TOKEN is not set.

Create ${ENV_FILE} from .devcontainer/.env.example and set either:
  OP_SERVICE_ACCOUNT_TOKEN_REF=op://Vault/Item/field
or:
  OP_SERVICE_ACCOUNT_TOKEN=ops_...

Then run:  source .devcontainer/scripts/load-op-env.sh
EOF
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 1
  fi
  exit 1
fi
