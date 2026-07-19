#!/usr/bin/env bash
# Health check for devcontainer Coolify debugging stack.
# Usage: bash .devcontainer/scripts/check_health.sh
set -uo pipefail

export PATH="${HOME}/.local/bin:${PATH}"
FAILED=0

check() {
  local label="$1"
  shift
  printf '==> %s\n' "$label"
  if "$@"; then
    printf '    OK\n\n'
  else
    printf '    FAIL\n\n' >&2
    FAILED=$((FAILED + 1))
  fi
}

check "chezmoi" chezmoi doctor
check "1Password" op whoami
check "Tailscale" tailscale status
check "Coolify CLI" command -v coolify
check "Coolify health" bash -c 'command -v coolify_health >/dev/null && coolify_health || coolify context verify'
check "Docker (local)" docker ps
check "jq" jq --version
check "httpie" http --version

if command -v dozzle_health >/dev/null 2>&1; then
  check "Dozzle" dozzle_health || true
else
  printf '==> Dozzle\n    SKIP (dozzle_functions not loaded)\n\n'
fi

if [ -n "${COOLIFY_DOCKER_HOST:-}" ] && command -v docker_remote_use >/dev/null 2>&1; then
  check "Remote Docker context" bash -c "docker_remote_use '${COOLIFY_DOCKER_HOST}' && docker ps"
else
  printf '==> Remote Docker\n    SKIP (set COOLIFY_DOCKER_HOST to enable)\n\n'
fi

if [ "$FAILED" -eq 0 ]; then
  printf 'All checks passed.\n'
  exit 0
fi

printf '%d check(s) failed.\n' "$FAILED" >&2
exit 1
