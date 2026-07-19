#!/usr/bin/env bash
# Bootstrap chezmoi dotfiles from the local workspace source tree.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

log() { printf '[post-create] %s\n' "$*"; }
die() { printf '[post-create] ERROR: %s\n' "$*" >&2; exit 1; }

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  die "OP_SERVICE_ACCOUNT_TOKEN is not set.
Rebuild the devcontainer with secrets:
  Command Palette -> Dev Containers: Rebuild Container and Reopen With Secrets"
fi

bootstrap_primordial() {
  bash "${REPO_ROOT}/.devcontainer/scripts/bootstrap-primordial.sh"
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    log "mise already installed"
    return 0
  fi
  log "Installing mise..."
  curl -fsSL https://mise.run | sh
  export PATH="${HOME}/.local/bin:${PATH}"
}

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    log "chezmoi already installed"
    return 0
  fi
  log "Installing chezmoi..."
  sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "${HOME}/.local/bin"
}

install_glances_client() {
  if command -v glances >/dev/null 2>&1; then
    return 0
  fi
  log "Installing glances client (optional remote host monitoring)..."
  pip3 install --user glances 2>/dev/null || log "glances install skipped (non-fatal)"
  export PATH="${HOME}/.local/bin:${PATH}"
}

apply_dotfiles() {
  log "Applying dotfiles from ${REPO_ROOT}..."
  cd "${REPO_ROOT}"
  if chezmoi source-path >/dev/null 2>&1; then
    chezmoi apply
  else
    chezmoi init --source "${REPO_ROOT}" --apply
  fi
}

verify_tools() {
  local failed=0
  for cmd in chezmoi mise op; do
    if command -v "$cmd" >/dev/null 2>&1; then
      log "OK: $cmd"
    else
      log "MISSING: $cmd"
      failed=1
    fi
  done
  if command -v coolify >/dev/null 2>&1; then
    log "OK: coolify ($(coolify version 2>/dev/null | head -1 || echo unknown))"
  else
    log "WARN: coolify not on PATH yet (may install on next chezmoi apply)"
  fi
  chezmoi doctor || true
  return "$failed"
}

main() {
  bootstrap_primordial
  install_mise
  install_chezmoi
  install_glances_client
  apply_dotfiles
  verify_tools
  log "Post-create complete."
}

main "$@"
