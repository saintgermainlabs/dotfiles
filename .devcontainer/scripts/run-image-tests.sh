#!/usr/bin/env bash
# Run primordial/base image tests against a published or local image.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${PRIMORDIAL_TEST_IMAGE:-ghcr.io/saintgermainlabs/linux-mgmt-primordial:24.04}"

usage() {
  cat <<EOF
Usage: run-image-tests.sh [OPTIONS] [TEST...]

Run integration tests inside a pulled primordial/base image.

Options:
  -i IMAGE   Image to test (default: ${IMAGE})
  -h         Show help

Tests (default: all):
  op-token          Check OP_SERVICE_ACCOUNT_TOKEN and op whoami
  primordial-env    Decrypt baked-in primordial.env.age (service token in container, or host app integration)

Environment:
  .devcontainer/.env                 op:// refs and optional literals (gitignored)
  .devcontainer/.env.runtime         resolved secrets for docker (gitignored, auto-generated)

Examples:
  cp .devcontainer/.env.example .devcontainer/.env
  $EDITOR .devcontainer/.env
  .devcontainer/scripts/run-image-tests.sh
EOF
}

declare -a TESTS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -i)
      IMAGE="${2:-}"
      shift 2
      ;;
    op-token)
      TESTS+=("op-token")
      shift
      ;;
    primordial-env)
      TESTS+=("primordial-env")
      shift
      ;;
    all)
      TESTS=("op-token")
      shift
      ;;
    *)
      echo "Unknown test or option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ ${#TESTS[@]} -eq 0 ]; then
  TESTS=("op-token")
fi

# shellcheck source=/dev/null
OP_USE_APP_INTEGRATION="${OP_USE_APP_INTEGRATION:-1}" source "${SCRIPT_DIR}/load-op-env.sh"

RUNTIME_ENV="${DEVCONTAINER_RUNTIME_ENV:-${SCRIPT_DIR}/../.env.runtime}"

run_test() {
  local name="$1"
  local script="$2"
  shift 2
  local -a extra_args=("$@")
  local mount_args=()
  local env_file_args=()
  local secrets_mount=()
  local op_mount=()
  if [ -d "${SCRIPT_DIR}" ]; then
    mount_args=(-v "${SCRIPT_DIR}:/opt/primordial/scripts:ro")
  fi
  if [ -d "${SCRIPT_DIR}/../secrets" ]; then
    secrets_mount=(-v "${SCRIPT_DIR}/../secrets:/opt/primordial/secrets:ro")
  fi
  if [ -f "${RUNTIME_ENV}" ]; then
    env_file_args=(--env-file "${RUNTIME_ENV}")
  fi
  if [ -e "${HOME}/.1password/agent.sock" ]; then
    op_mount=(
      -v "${HOME}/.1password:/home/vscode/.1password"
      -e OP_USE_APP_INTEGRATION=true
      -e OP_BIOMETRIC_UNLOCK_ENABLED=true
      -e "OP_AGE_KEY_REF=${OP_AGE_KEY_REF:-op://Security Keys/chezmoi age key/key.txt}"
    )
    extra_args=(--user vscode "${extra_args[@]}")
  fi
  printf '\n==> Running test: %s\n' "$name"
  docker run --rm \
    "${mount_args[@]}" \
    "${secrets_mount[@]}" \
    "${op_mount[@]}" \
    "${env_file_args[@]}" \
    "${extra_args[@]}" \
    "${IMAGE}" \
    bash "${script}"
}

for test in "${TESTS[@]}"; do
  case "$test" in
    op-token)
      run_test "op-token" "/opt/primordial/scripts/test/check-op-token.sh"
      ;;
    primordial-env)
      if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
        run_test "primordial-env" "/opt/primordial/scripts/test/check-primordial-env-bootstrap.sh"
      elif [ -e "${HOME}/.1password/agent.sock" ]; then
        printf '\n==> Running test: primordial-env (host app integration)\n'
        printf '    Docker cannot reach the 1Password desktop app on this host;\n'
        printf '    running bootstrap on the host instead.\n\n'
        bash "${SCRIPT_DIR}/test/check-primordial-env-host.sh"
      else
        echo "primordial-env requires OP_SERVICE_ACCOUNT_TOKEN or 1Password app integration on the host." >&2
        exit 1
      fi
      ;;
  esac
done

printf '\nAll requested image tests passed.\n'
