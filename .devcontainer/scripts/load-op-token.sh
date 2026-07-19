#!/usr/bin/env bash
# Back-compat wrapper — use load-op-env.sh for all OP variables.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/load-op-env.sh"
