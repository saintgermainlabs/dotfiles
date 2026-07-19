#!/usr/bin/env bash
# Decrypt the primordial age-encrypted env baked into the image at build time.
set -euo pipefail

ENCRYPTED="${PRIMORDIAL_ENV_AGE:-/opt/primordial/secrets/primordial.env.age}"
OUT="${PRIMORDIAL_ENV_FILE:-/var/lib/primordial/primordial.env}"
AGE_KEY="${AGE_KEY:-${HOME}/.config/age/key.txt}"

log() { printf '[decrypt-primordial-env] %s\n' "$*"; }

if [ ! -f "${ENCRYPTED}" ]; then
  log "No encrypted primordial env at ${ENCRYPTED}; skipping."
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
else
  echo "age binary is required to decrypt primordial env." >&2
  exit 1
fi

mkdir -p "$(dirname "${OUT}")"
if ! cmp -s "${TMP_OUT}" "${OUT}" 2>/dev/null; then
  mv "${TMP_OUT}" "${OUT}"
  chmod 600 "${OUT}"
  log "Wrote ${OUT}"
else
  log "${OUT} unchanged"
fi

# Export variables into the current shell for the remainder of bootstrap.
set -a
# shellcheck disable=SC1090
source "${OUT}"
set +a

log "Sourced ${OUT} into environment"
