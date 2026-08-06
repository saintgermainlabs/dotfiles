## @module openclaw
## @title OpenClaw
## @description Provides shell commands for managing and interacting with OpenClaw.
## @category AI & Automation
## @requires openclaw
## @tags openclaw ai agent gateway skills remote
## @source functions.sh
## @source aliases.sh

# shellcheck shell=bash
#
# Source this file from Bash or Zsh to load the remote OpenClaw helpers.

if [ -n "${BASH_VERSION:-}" ]; then
  _oc_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _oc_module_file="${(%):-%N}"
else
  _oc_module_file="$0"
fi

_oc_module_dir="$(CDPATH= cd -- "$(dirname -- "$_oc_module_file")" && pwd)"

# Optional private overrides (never commit secrets here).
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/openclaw/environment" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${XDG_CONFIG_HOME:-$HOME/.config}/openclaw/environment"
  set +a
fi

# shellcheck source=functions.sh
. "$_oc_module_dir/functions.sh"

case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_oc_module_dir/aliases.sh"
    ;;
esac

unset _oc_module_file _oc_module_dir
