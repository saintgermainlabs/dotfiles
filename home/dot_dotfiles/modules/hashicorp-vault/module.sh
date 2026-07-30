# shellcheck shell=bash
#
# Source this file from Bash or Zsh to load the HashiCorp Vault helpers.

if [ -n "${BASH_VERSION:-}" ]; then
  _vault_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  _vault_module_file="${(%):-%N}"
else
  _vault_module_file="$0"
fi

_vault_module_dir="$(CDPATH= cd -- "$(dirname -- "$_vault_module_file")" && pwd)"

# shellcheck source=functions.sh
. "$_vault_module_dir/functions.sh"

case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_vault_module_dir/aliases.sh"
    ;;
esac

unset _vault_module_file _vault_module_dir

