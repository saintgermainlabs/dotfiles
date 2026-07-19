#!/usr/bin/env bash
# Decrypt secrets/env.txt.age into a shell-sourceable .env file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ENCRYPTED="${ENCRYPTED_ENV_FILE:-${REPO_ROOT}/secrets/env.txt.age}"
OUT="${DECRYPTED_ENV_FILE:-${HOME}/.dotfiles/dot_env/.env}"
AGE_KEY="${AGE_KEY:-${HOME}/.config/age/key.txt}"

log() { printf '[decrypt-env] %s\n' "$*"; }

if [ ! -f "${ENCRYPTED}" ]; then
  log "No encrypted env at ${ENCRYPTED}; skipping."
  exit 0
fi

if [ ! -f "${AGE_KEY}" ]; then
  echo "Age identity not found at ${AGE_KEY}; run setup-age-key.sh first." >&2
  exit 1
fi

TMP_OUT="$(mktemp)"
trap 'rm -f "${TMP_OUT}"' EXIT

if command -v age >/dev/null 2>&1; then
  age --decrypt --identity "${AGE_KEY}" --output "${TMP_OUT}" "${ENCRYPTED}"
elif command -v chezmoi >/dev/null 2>&1 && chezmoi age decrypt --help >/dev/null 2>&1; then
  chezmoi age decrypt --identity "${AGE_KEY}" "${ENCRYPTED}" > "${TMP_OUT}"
else
  echo "No age decrypt tool available (age binary or chezmoi age decrypt)." >&2
  exit 1
fi

if ! cmp -s "${TMP_OUT}" "${OUT}" 2>/dev/null; then
  mkdir -p "$(dirname "${OUT}")"
  mv "${TMP_OUT}" "${OUT}"
  chmod 600 "${OUT}"
  log "Wrote ${OUT}"
else
  log "${OUT} unchanged"
fi
