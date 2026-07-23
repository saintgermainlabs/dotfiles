#!/usr/bin/env bash
# Install shdoc (https://github.com/reconquest/shdoc) into .devcontainer/tools/shdoc/bin.
set -euo pipefail

SHDOC_VERSION="${SHDOC_VERSION:-v1.4}"
SHDOC_REPO="${SHDOC_REPO:-https://github.com/reconquest/shdoc.git}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${1:-${SCRIPT_DIR}}"
SRC_DIR="${INSTALL_ROOT}/src"
BIN_DIR="${INSTALL_ROOT}/bin"
STAMP="${INSTALL_ROOT}/.installed-${SHDOC_VERSION}"

log() { printf '[install-shdoc] %s\n' "$*"; }
warn() { printf '[install-shdoc] WARN: %s\n' "$*" >&2; }

ensure_gawk() {
  if command -v gawk >/dev/null 2>&1; then
    return 0
  fi
  log "Installing gawk (required by shdoc)..."
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends gawk
  else
    apt-get update
    apt-get install -y --no-install-recommends gawk
  fi
}

install_shdoc() {
  if [ -x "${BIN_DIR}/shdoc" ] && [ -f "${STAMP}" ]; then
    log "shdoc already installed at ${BIN_DIR}/shdoc (${SHDOC_VERSION})"
    return 0
  fi

  ensure_gawk
  mkdir -p "${BIN_DIR}" "${SRC_DIR}"

  if [ ! -d "${SRC_DIR}/.git" ]; then
    log "Cloning ${SHDOC_REPO} (${SHDOC_VERSION})..."
    git clone --depth 1 --branch "${SHDOC_VERSION}" "${SHDOC_REPO}" "${SRC_DIR}"
  else
    log "Updating existing clone in ${SRC_DIR}..."
    git -C "${SRC_DIR}" fetch --depth 1 origin "refs/tags/${SHDOC_VERSION}" 2>/dev/null \
      || git -C "${SRC_DIR}" fetch --depth 1 origin "${SHDOC_VERSION}" 2>/dev/null \
      || true
    git -C "${SRC_DIR}" checkout "${SHDOC_VERSION}" 2>/dev/null || true
  fi

  log "Installing shdoc to ${INSTALL_ROOT}..."
  install -d "${BIN_DIR}"
  install -m 0755 "${SRC_DIR}/shdoc" "${BIN_DIR}/shdoc"
  if [ -f "${SRC_DIR}/contrib/shdoc.1" ]; then
    install -d "${INSTALL_ROOT}/share/man/man1"
    install -m 0644 "${SRC_DIR}/contrib/shdoc.1" "${INSTALL_ROOT}/share/man/man1/shdoc.1"
  fi
  date -u +%Y-%m-%dT%H:%M:%SZ >"${STAMP}"
  log "Installed: $("${BIN_DIR}/shdoc" --version 2>/dev/null || echo shdoc)"
}

install_shdoc
