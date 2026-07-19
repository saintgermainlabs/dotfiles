#!/usr/bin/env bats

# Integration tests for published primordial/base devcontainer images.
# Requires OP_SERVICE_ACCOUNT_TOKEN or OP_SERVICE_ACCOUNT_TOKEN_REF on the host.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  RUNNER="${REPO_ROOT}/.devcontainer/scripts/run-image-tests.sh"
  IMAGE="${PRIMORDIAL_TEST_IMAGE:-ghcr.io/saintgermainlabs/linux-mgmt-primordial:24.04}"
}

@test "[devcontainer] primordial image: OP service token authenticates op" {
  if [ ! -f "${REPO_ROOT}/.devcontainer/.env" ] && \
     [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] && \
     [ -z "${OP_SERVICE_ACCOUNT_TOKEN_REF:-}" ]; then
    skip "Create .devcontainer/.env from .env.example or set OP_SERVICE_ACCOUNT_TOKEN"
  fi
  if ! command -v docker >/dev/null 2>&1; then
    skip "docker not available"
  fi
  run env PRIMORDIAL_TEST_IMAGE="${IMAGE}" bash "${RUNNER}" op-token
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK: op authenticated"* ]]
}
