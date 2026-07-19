#!/usr/bin/env bash
# Host-side primordial env test (local laptop with 1Password app integration).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SECRETS="$(cd "${SCRIPT_DIR}/../secrets" && pwd)"
# shellcheck source=../lib/op-auth.sh
source "${SCRIPT_DIR}/lib/op-auth.sh"

export OP_USE_APP_INTEGRATION="${OP_USE_APP_INTEGRATION:-1}"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

export PRIMORDIAL_ENV_AGE="${REPO_SECRETS}/primordial.env.age"
export PRIMORDIAL_ENV_FILE="${TEST_DIR}/primordial.env"
export AGE_DIR="${TEST_DIR}/age"
export AGE_KEY="${AGE_DIR}/key.txt"

if [ ! -r "${PRIMORDIAL_ENV_AGE}" ]; then
  echo "[test-primordial-env-host] FAIL: cannot read ${PRIMORDIAL_ENV_AGE}" >&2
  echo "If you encrypted with sudo, fix ownership:" >&2
  echo "  sudo chown \"\$USER:\$USER\" ${PRIMORDIAL_ENV_AGE}" >&2
  echo "  chmod 600 ${PRIMORDIAL_ENV_AGE}" >&2
  exit 1
fi

bash "${SCRIPT_DIR}/authenticate-op.sh"
bash "${SCRIPT_DIR}/setup-age-key.sh"
bash "${SCRIPT_DIR}/decrypt-primordial-env.sh"
bash "${SCRIPT_DIR}/test/check-primordial-env.sh"
