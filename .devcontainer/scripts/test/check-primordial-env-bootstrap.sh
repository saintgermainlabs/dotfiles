#!/usr/bin/env bash
# Integration test: full bootstrap path through primordial env decrypt.
set -euo pipefail

export HOME="${HOME:-/root}"
export OP_USE_APP_INTEGRATION="${OP_USE_APP_INTEGRATION:-1}"

bash /opt/primordial/scripts/authenticate-op.sh
bash /opt/primordial/scripts/setup-age-key.sh
bash /opt/primordial/scripts/test/check-primordial-env.sh
