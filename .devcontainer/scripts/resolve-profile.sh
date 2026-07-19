#!/usr/bin/env bash
# Resolve local vs remote devcontainer profile before build/start/bootstrap.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROFILE_FILE="${DEVCONTAINER_PROFILE_FILE:-${DEVCONTAINER_DIR}/profile}"
RUNTIME_ENV="${DEVCONTAINER_PROFILE_RUNTIME:-${DEVCONTAINER_DIR}/.profile.runtime}"

log() { printf '[resolve-profile] %s\n' "$*"; }
warn() { printf '[resolve-profile] WARN: %s\n' "$*" >&2; }

normalize_profile() {
  case "${1,,}" in
    local|remote|devops) printf '%s\n' "${1,,}" ;;
    *)
      warn "Unknown profile '${1}'; expected local or remote"
      return 1
      ;;
  esac
}

host_has_op_app_integration() {
  [ -e "${HOME}/.1password/agent.sock" ]
}

detect_profile_from_host() {
  local host="${1:-}"

  case "${host}" in
    Ubuntu-24|ubuntu-24|ubuntu-server)
      printf 'remote\n'
      return 0
      ;;
  esac

  if host_has_op_app_integration; then
    printf 'local\n'
    return 0
  fi

  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    printf 'remote\n'
    return 0
  fi

  printf 'local\n'
}

read_profile() {
  local profile=""

  if [ -n "${DEVCONTAINER_PROFILE:-}" ]; then
    normalize_profile "${DEVCONTAINER_PROFILE}"
    return 0
  fi

  if [ -f "${PROFILE_FILE}" ]; then
    profile="$(tr -d '[:space:]' < "${PROFILE_FILE}")"
    if [ -n "${profile}" ]; then
      normalize_profile "${profile}"
      return 0
    fi
  fi

  detect_profile_from_host "$(hostname -s 2>/dev/null || hostname)"
}

apply_profile() {
  local profile="$1"

  case "${profile}" in
    local)
      export DEVCONTAINER_PROFILE=local
      export DOTFILES_ROLE=local
      export DOTFILES_HOSTNAME=devops-local01
      export OP_USE_APP_INTEGRATION=true
      export OP_BIOMETRIC_UNLOCK_ENABLED=true
      ;;
    remote)
      export DEVCONTAINER_PROFILE=remote
      export DOTFILES_ROLE=remote
      export DOTFILES_HOSTNAME=devops-remote01
      unset OP_USE_APP_INTEGRATION OP_BIOMETRIC_UNLOCK_ENABLED
      ;;
    devops)
      export DEVCONTAINER_PROFILE=devops
      export DOTFILES_ROLE=devops
      export DOTFILES_HOSTNAME=devops-dev01
      unset OP_USE_APP_INTEGRATION OP_BIOMETRIC_UNLOCK_ENABLED
      ;;
  esac
}

write_runtime_env() {
  : >"${RUNTIME_ENV}"
  chmod 600 "${RUNTIME_ENV}"

  printf 'DEVCONTAINER_PROFILE=%q\n' "${DEVCONTAINER_PROFILE}" >>"${RUNTIME_ENV}"
  printf 'DOTFILES_ROLE=%q\n' "${DOTFILES_ROLE}" >>"${RUNTIME_ENV}"
  printf 'DOTFILES_HOSTNAME=%q\n' "${DOTFILES_HOSTNAME}" >>"${RUNTIME_ENV}"

  if [ "${DEVCONTAINER_PROFILE}" = "local" ]; then
    printf 'OP_USE_APP_INTEGRATION=%q\n' true >>"${RUNTIME_ENV}"
    printf 'OP_BIOMETRIC_UNLOCK_ENABLED=%q\n' true >>"${RUNTIME_ENV}"
  fi
}

ensure_mount_sources() {
  # Bind-mount sources must exist on the host before the devcontainer starts.
  mkdir -p "${HOME}/.ssh" "${HOME}/.1password"
  chmod 700 "${HOME}/.ssh" 2>/dev/null || true
  log "Ensured mount sources ${HOME}/.ssh and ${HOME}/.1password exist"
}

main() {
  local profile
  profile="$(read_profile)"
  apply_profile "${profile}"
  write_runtime_env
  ensure_mount_sources

  log "Profile: ${DEVCONTAINER_PROFILE}"
  log "DOTFILES_ROLE=${DOTFILES_ROLE}"
  log "DOTFILES_HOSTNAME=${DOTFILES_HOSTNAME}"
  log "Wrote ${RUNTIME_ENV}"
}

main "$@"
