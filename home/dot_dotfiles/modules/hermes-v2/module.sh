## @module hermes-v2
## @title Hermes Gate
## @description Local Docker TUI client for remote Hermes Agent tmux sessions (Hermes Gate).
## @category AI & Automation
## @requires docker git ssh
## @tags hermes hermes-gate ai agent tui remote
## @source functions.sh
## @source aliases.sh

# shellcheck shell=bash
#
# Source this file from Bash or Zsh to load the Hermes Gate helpers.

if [ -n "${BASH_VERSION:-}" ]; then
  _hg_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _hg_module_file="${(%):-%N}"
else
  _hg_module_file="$0"
fi

_hg_module_dir="$(CDPATH= cd -- "$(dirname -- "$_hg_module_file")" && pwd)"

# Optional private overrides (never commit secrets here).
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/hermes-gate/environment" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${XDG_CONFIG_HOME:-$HOME/.config}/hermes-gate/environment"
  set +a
fi

# shellcheck source=functions.sh
. "$_hg_module_dir/functions.sh"

case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_hg_module_dir/aliases.sh"
    # shellcheck source=completions.bash
    [ -r "$_hg_module_dir/completions.bash" ] && . "$_hg_module_dir/completions.bash"
    # shellcheck source=completions.zsh
    [ -r "$_hg_module_dir/completions.zsh" ] && . "$_hg_module_dir/completions.zsh"
    ;;
esac

unset _hg_module_file _hg_module_dir
