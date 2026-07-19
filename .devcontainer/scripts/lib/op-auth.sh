#!/usr/bin/env bash
# Shared 1Password readiness checks for app integration and service accounts.
set -euo pipefail

op_app_integration_enabled() {
  [ -n "${OP_USE_APP_INTEGRATION:-}" ] && [ "${OP_USE_APP_INTEGRATION}" != "0" ]
}

op_agent_socket_ready() {
  [ -S "${HOME}/.1password/agent.sock" ] || [ -L "${HOME}/.1password/agent.sock" ] || [ -e "${HOME}/.1password/agent.sock" ]
}

op_can_access_vault() {
  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    return 0
  fi

  if op_app_integration_enabled && op_agent_socket_ready; then
    local ref="${OP_AGE_KEY_REF:-op://Security Keys/chezmoi age key/key.txt}"
    op read "${ref}" >/dev/null 2>&1
    return $?
  fi

  op whoami >/dev/null 2>&1
}

op_auth_summary() {
  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    printf 'service account token'
    return 0
  fi

  if op_app_integration_enabled && op_agent_socket_ready; then
    printf '1Password app integration'
    return 0
  fi

  op whoami 2>/dev/null | head -1 || printf 'unknown'
}
