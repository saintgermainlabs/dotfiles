## @module hermes
## @title Hermes Agent
## @description Shell commands for managing a remote Hermes Agent Docker container.
## @category AI & Automation
## @requires hermes
## @tags hermes ai agent gateway skills remote
## @source functions.sh
## @source hwedit.sh
## @source aliases.sh

# shellcheck shell=bash
#
# Source this file from Bash or Zsh to load the remote Hermes helpers.

if [ -n "${BASH_VERSION:-}" ]; then
  _hm_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _hm_module_file="${(%):-%N}"
else
  _hm_module_file="$0"
fi

_hm_module_dir="$(CDPATH= cd -- "$(dirname -- "$_hm_module_file")" && pwd)"

# Optional private overrides (never commit secrets here).
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/hermes/environment" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${XDG_CONFIG_HOME:-$HOME/.config}/hermes/environment"
  set +a
fi

# shellcheck source=functions.sh
. "$_hm_module_dir/functions.sh"
# shellcheck source=hwedit.sh
[ -r "$_hm_module_dir/hwedit.sh" ] && . "$_hm_module_dir/hwedit.sh"

case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_hm_module_dir/aliases.sh"
    # shellcheck source=completions.bash
    [ -r "$_hm_module_dir/completions.bash" ] && . "$_hm_module_dir/completions.bash"
    # shellcheck source=completions.zsh
    [ -r "$_hm_module_dir/completions.zsh" ] && . "$_hm_module_dir/completions.zsh"
    ;;
esac

unset _hm_module_file _hm_module_dir
