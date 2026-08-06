# shellcheck shell=bash
#
# Local-to-remote helpers — source from Bash or Zsh.

## @module local_to_remote
## @title Local to Remote
## @description Provides SSH and rsync helpers for running remote commands, transferring files, and editing allowlisted remote configuration.
## @category Remote
## @requires ssh
## @requires rsync
## @tags ssh remote rsync upload download server config edit
## @source local_to_remote.sh

if [ -n "${BASH_VERSION:-}" ]; then
  _ltr_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _ltr_module_file="${(%):-%N}"
else
  _ltr_module_file="$0"
fi

_ltr_module_dir="$(
  CDPATH= cd -- "$(dirname -- "$_ltr_module_file")" && pwd
)"

# shellcheck source=local_to_remote.sh
. "$_ltr_module_dir/local_to_remote.sh"

unset _ltr_module_file _ltr_module_dir
