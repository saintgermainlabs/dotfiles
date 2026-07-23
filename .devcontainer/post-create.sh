#!/usr/bin/env bash
# Bootstrap chezmoi dotfiles from the local workspace source tree.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"
# shellcheck source=scripts/lib/op-auth.sh
source "${REPO_ROOT}/.devcontainer/scripts/lib/op-auth.sh"
# shellcheck source=scripts/lib/load-profile.sh
source "${REPO_ROOT}/.devcontainer/scripts/lib/load-profile.sh"

log() { printf '[post-create] %s\n' "$*"; }
die() { printf '[post-create] ERROR: %s\n' "$*" >&2; exit 1; }

load_devcontainer_profile "${REPO_ROOT}" || die "Could not load devcontainer profile"
log "Profile=${DEVCONTAINER_PROFILE:-unknown} role=${DOTFILES_ROLE:-unknown} hostname=${DOTFILES_HOSTNAME:-unknown}"

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] && ! op_can_access_vault; then
  die "1Password is not authenticated.
Local: enable 1Password desktop app CLI integration and rebuild (see README).
Remote: set OP_SERVICE_ACCOUNT_TOKEN or rebuild with secrets."
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

install_shdoc() {
  local shdoc_dir="${REPO_ROOT}/.devcontainer/tools/shdoc"
  local shdoc_bin="${shdoc_dir}/bin"
  if [ ! -x "${shdoc_dir}/install.sh" ]; then
    log "shdoc installer missing at ${shdoc_dir}/install.sh; skipping"
    return 0
  fi
  log "Installing shdoc..."
  bash "${shdoc_dir}/install.sh" "${shdoc_dir}" || {
    log "shdoc install failed (non-fatal)"
    return 0
  }
  export PATH="${shdoc_bin}:${PATH}"
  sudo tee /etc/profile.d/shdoc-devcontainer.sh >/dev/null <<EOF
# Added by sgdotfilesfresh post-create — shdoc shell documentation generator.
export PATH="${shdoc_bin}:\${PATH}"
EOF
  sudo chmod 644 /etc/profile.d/shdoc-devcontainer.sh
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
  if command -v shdoc >/dev/null 2>&1; then
    log "OK: shdoc ($(shdoc --version 2>/dev/null || echo installed))"
  else
    log "WARN: shdoc not on PATH"
  fi
  chezmoi doctor || true
  return "$failed"
}

main() {
  bootstrap_primordial
  install_mise
  install_chezmoi
  install_glances_client
  install_shdoc
  apply_dotfiles
  verify_tools
  log "Post-create complete."
}

main "$@"
