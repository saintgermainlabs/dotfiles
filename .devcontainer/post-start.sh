#!/usr/bin/env bash
# Start Tailscale and optionally configure remote Docker context.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/load-profile.sh
source "${REPO_ROOT}/.devcontainer/scripts/lib/load-profile.sh"
load_devcontainer_profile "${REPO_ROOT}" || true

export PATH="${HOME}/.local/bin:${PATH}"
TS_SOCKET="${TS_SOCKET:-/var/run/tailscale/tailscaled.sock}"
TS_STATE="${TS_STATE:-/var/lib/tailscale/tailscaled.state}"
TS_HOSTNAME="${DOTFILES_HOSTNAME:-devops-dev01}"

log() { printf '[post-start] %s\n' "$*"; }
warn() { printf '[post-start] WARN: %s\n' "$*" >&2; }

start_tailscaled() {
  if [ ! -x "$(command -v tailscaled)" ]; then
    warn "tailscaled not installed yet; run chezmoi apply if this is first boot"
    return 1
  fi

  if sudo tailscale status >/dev/null 2>&1; then
    log "Tailscale already connected"
    return 0
  fi

  if ! pgrep -x tailscaled >/dev/null 2>&1; then
    log "Starting tailscaled..."
    sudo mkdir -p "$(dirname "$TS_SOCKET")"
    sudo tailscaled \
      --state="${TS_STATE}" \
      --socket="${TS_SOCKET}" \
      --port=41641 &
    sleep 2
  fi
  return 0
}

connect_tailscale() {
  if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
    warn "TAILSCALE_AUTHKEY not set; skipping tailscale up.
Rebuild with secrets or export TAILSCALE_AUTHKEY manually."
    return 0
  fi

  if sudo tailscale status >/dev/null 2>&1; then
    log "Tailscale already up"
    sudo tailscale status | head -10
    return 0
  fi

  log "Connecting Tailscale as ${TS_HOSTNAME}..."
  sudo tailscale up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname="${TS_HOSTNAME}" \
    --accept-routes \
    --socket="${TS_SOCKET}"
  sudo tailscale status | head -10
}

setup_remote_docker_context() {
  if [ "${DOTFILES_ROLE:-}" = "remote" ]; then
    log "Remote devcontainer uses local Docker socket; skipping SSH context setup"
    return 0
  fi

  local host="${COOLIFY_DOCKER_HOST:-}"
  [ -z "$host" ] && return 0

  if ! command -v docker >/dev/null 2>&1; then
    warn "docker CLI not available; skipping remote context setup"
    return 0
  fi

  local ctx_name="coolify-remote"
  local docker_host="ssh://${host}"

  if docker context inspect "$ctx_name" >/dev/null 2>&1; then
    log "Docker context '${ctx_name}' already exists"
  else
    log "Creating Docker context '${ctx_name}' -> ${docker_host}"
    docker context create "$ctx_name" --docker "host=${docker_host}"
  fi
}

smoke_check_coolify() {
  if command -v coolify >/dev/null 2>&1; then
    coolify context verify 2>/dev/null && log "Coolify context verified" \
      || warn "Coolify context verify failed (configure context via chezmoi apply)"
  fi
}

main() {
  start_tailscaled || true
  connect_tailscale || true
  setup_remote_docker_context || true
  smoke_check_coolify || true
  log "Post-start complete."
}

main "$@"
