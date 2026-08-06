# shellcheck shell=bash
#
# Coolify manager — wrap the Coolify CLI for apps and services.
# Source from Bash or Zsh.

## @module coolify-manager
## @title Coolify Manager
## @description Provides shell helpers for finding and inspecting Coolify apps and services via the Coolify CLI.
## @category Coolify
## @requires coolify
## @requires jq
## @tags coolify apps services deploy remote paas
## @source functions.sh
## @source aliases.sh

if [ -n "${BASH_VERSION:-}" ]; then
  _cm_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _cm_module_file="${(%):-%N}"
else
  _cm_module_file="$0"
fi

_cm_module_dir="$(
  CDPATH= cd -- "$(dirname -- "$_cm_module_file")" && pwd
)"

# Optional private overrides (never commit secrets here).
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/coolify-manager/environment" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${XDG_CONFIG_HOME:-$HOME/.config}/coolify-manager/environment"
  set +a
fi

# shellcheck source=functions.sh
. "$_cm_module_dir/functions.sh"

case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_cm_module_dir/aliases.sh"
    ;;
esac

unset _cm_module_file _cm_module_dir
