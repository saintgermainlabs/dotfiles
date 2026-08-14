# shellcheck shell=bash
#
# Hermes Gate wrappers — clone lives outside chezmoi; this module only
# launches upstream run.sh. Compatible with Bash and Zsh.

: "${HERMES_GATE_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/hermes-gate}"
: "${HERMES_GATE_REPO:=https://github.com/LehaoLin/hermes-gate.git}"
: "${HERMES_GATE_CONTAINER:=hermes-gate}"

_hg_error() {
  printf 'hermes-gate: %s\n' "$*" >&2
}

_hg_module_install() {
  local _hg_here
  if [ -n "${BASH_VERSION:-}" ]; then
    _hg_here="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    # shellcheck disable=SC2296
    _hg_here="$(CDPATH= cd -- "$(dirname -- "${(%):-%N}")" && pwd)"
  else
    _hg_here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  fi
  printf '%s/install.sh' "$_hg_here"
}

_hg_require_checkout() {
  if [ -x "${HERMES_GATE_DIR}/run.sh" ]; then
    return 0
  fi
  _hg_error "Hermes Gate is not cloned at ${HERMES_GATE_DIR}"
  _hg_error "run: $(_hg_module_install)"
  return 1
}

_hg_run() {
  _hg_require_checkout || return
  command -v docker >/dev/null 2>&1 || {
    _hg_error "required command not found: docker"
    return 127
  }
  (
    CDPATH= cd -- "$HERMES_GATE_DIR" || exit 1
    ./run.sh "$@"
  )
}

# Print the local checkout path.
hg_dir() {
  printf '%s\n' "$HERMES_GATE_DIR"
}

# Start the Hermes Gate TUI (or pass through run.sh commands).
# Usage: hg
#        hg rebuild|update|stop
hg() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'EOF'
Usage:
  hg                  Start the Hermes Gate TUI
  hg rebuild          Force rebuild the Docker image, then start
  hg update           git pull, rebuild, then start
  hg stop             Stop and remove the container
  hg_rebuild          Same as: hg rebuild
  hg_update           Same as: hg update
  hg_stop             Same as: hg stop
  hg_status           Clone + Docker container/image status
  hg_dir              Print the local checkout path

Env:
  HERMES_GATE_DIR         Checkout path (default: ~/.local/share/hermes-gate)
  HERMES_GATE_REPO        Git remote (default: LehaoLin/hermes-gate)
  HERMES_GATE_CONTAINER   Docker container name (default: hermes-gate)

Clone once with the module install.sh. First start builds the image.
This is a local TUI client; remote Hermes CLI/config stays on `hm_*`.
EOF
    return 0
  fi
  _hg_run "$@"
}

hermes_gate() {
  hg "$@"
}

hg_rebuild() {
  _hg_run rebuild
}

hg_update() {
  _hg_run update
}

hg_stop() {
  _hg_run stop
}

# Clone + Docker status (does not start the TUI).
hg_status() {
  local _hg_running _hg_exists

  printf 'Checkout:   %s\n' "$HERMES_GATE_DIR"
  if [ -x "${HERMES_GATE_DIR}/run.sh" ]; then
    printf 'Clone:      ok\n'
  else
    printf 'Clone:      missing (run %s)\n' "$(_hg_module_install)"
  fi

  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker:     not found\n'
    return 0
  fi
  printf 'Docker:     ok\n'

  _hg_running="$(docker inspect -f '{{.State.Running}}' "$HERMES_GATE_CONTAINER" 2>/dev/null || true)"
  _hg_exists="$(docker inspect -f '{{.Id}}' "$HERMES_GATE_CONTAINER" 2>/dev/null || true)"

  if [ "$_hg_running" = "true" ]; then
    printf 'Container:  running (%s)\n' "$HERMES_GATE_CONTAINER"
  elif [ -n "$_hg_exists" ]; then
    printf 'Container:  stopped (%s)\n' "$HERMES_GATE_CONTAINER"
  else
    printf 'Container:  not created\n'
  fi

  printf '\n--- docker ---\n'
  docker ps -a --filter "name=^/${HERMES_GATE_CONTAINER}$" \
    --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null || true

  unset _hg_running _hg_exists
}
