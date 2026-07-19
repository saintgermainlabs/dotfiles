#!/usr/bin/env bash
# Encrypt environment variables into an age-encrypted env.txt.age file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECIPIENT="${AGE_RECIPIENT:-age1m7qs8zz9r2c9qqflahclxd0z6gfpeq44pawv7vwzw03a93dk4usscnxazq}"

usage() {
  cat <<EOF
Usage: encrypt-env.sh [-o OUT.age] [OPTIONS]

Create an age-encrypted env file from environment variables.

Options:
  -o OUT.age    Output encrypted file (default: secrets/env.txt.age)
  -f FILE       Read KEY=VALUE lines from FILE (repeatable)
  VAR           Read value from current environment
  KEY=VALUE     Explicit pair

Requires: age

Examples:
  encrypt-env.sh COOLIFY_API_TOKEN GEMINI_API_KEY
  encrypt-env.sh -f ~/.dotfiles/dot_env/.env -o secrets/env.txt.age
  COOLIFY_API_TOKEN=secret encrypt-env.sh COOLIFY_API_TOKEN
EOF
}

OUT=""
declare -a FORWARD=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -o)
      OUT="${2:-}"
      shift 2
      ;;
    *)
      FORWARD+=("$1")
      shift
      ;;
  esac
done

if [ -z "${OUT}" ]; then
  REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  OUT="${REPO_ROOT}/secrets/env.txt.age"
fi

if ! command -v age >/dev/null 2>&1; then
  echo "age is required; install it or use the primordial devcontainer image." >&2
  exit 1
fi

TMP_PLAIN="$(mktemp)"
TMP_AGE="$(mktemp)"
trap 'rm -f "${TMP_PLAIN}" "${TMP_AGE}"' EXIT

bash "${SCRIPT_DIR}/build-env-plaintext.sh" -o "${TMP_PLAIN}" "${FORWARD[@]}"

age -r "${RECIPIENT}" -o "${TMP_AGE}" "${TMP_PLAIN}"
mkdir -p "$(dirname "${OUT}")"
mv "${TMP_AGE}" "${OUT}"
chmod 600 "${OUT}"

echo "Encrypted env written to ${OUT}"
