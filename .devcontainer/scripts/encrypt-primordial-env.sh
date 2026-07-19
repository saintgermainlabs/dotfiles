#!/usr/bin/env bash
# Encrypt .devcontainer/secrets/primordial.env → primordial.env.age
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$(cd "${SCRIPT_DIR}/../secrets" && pwd)"
PLAIN="${SECRETS_DIR}/primordial.env"
OUT="${SECRETS_DIR}/primordial.env.age"

if [ ! -f "${PLAIN}" ]; then
  echo "Missing ${PLAIN}" >&2
  echo "Copy primordial.env.example to primordial.env and fill in values." >&2
  exit 1
fi

bash "${SCRIPT_DIR}/encrypt-env.sh" -f "${PLAIN}" -o "${OUT}"
echo "Commit ${OUT} so the primordial image build includes the encrypted env."
