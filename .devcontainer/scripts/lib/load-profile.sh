#!/usr/bin/env bash
# Source resolved devcontainer profile vars inside the container.
set -euo pipefail

load_devcontainer_profile() {
  local repo_root="${1:-}"
  local runtime="${DEVCONTAINER_PROFILE_RUNTIME:-${repo_root}/.devcontainer/.profile.runtime}"

  if [ -f "${runtime}" ]; then
    set -a
    # shellcheck disable=SC1090
    source "${runtime}"
    set +a
    return 0
  fi

  if [ -n "${repo_root}" ] && [ -x "${repo_root}/.devcontainer/scripts/resolve-profile.sh" ]; then
    bash "${repo_root}/.devcontainer/scripts/resolve-profile.sh"
    set -a
    # shellcheck disable=SC1090
    source "${runtime}"
    set +a
    return 0
  fi

  return 1
}
