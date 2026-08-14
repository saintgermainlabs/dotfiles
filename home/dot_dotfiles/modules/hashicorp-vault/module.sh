# shellcheck shell=bash
#
# HashiCorp Vault dotfiles module.

## @module hashicorp-vault
## @title HashiCorp Vault
## @description Loads shell functions and interactive aliases for working with HashiCorp Vault.
## @category Security
## @requires vault
## @tags vault hashicorp secrets credentials security
## @source functions.sh
## @source aliases.sh

# ---------------------------------------------------------------------------
# Module initialization
# ---------------------------------------------------------------------------

# Determine the directory containing this module.
if [ -n "${BASH_VERSION:-}" ]; then
  _vault_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  _vault_module_file="${(%):-%N}"
else
  _vault_module_file="$0"
fi

_vault_module_dir="$(
  CDPATH= cd -- "$(dirname -- "$_vault_module_file")" && pwd
)"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# shellcheck source=functions.sh
. "$_vault_module_dir/functions.sh"

# ---------------------------------------------------------------------------
# Interactive aliases
# ---------------------------------------------------------------------------

# Aliases are only needed in interactive shells.
case $- in
  *i*)
    # shellcheck source=aliases.sh
    . "$_vault_module_dir/aliases.sh"
    # shellcheck source=completions.bash
    [ -r "$_vault_module_dir/completions.bash" ] && . "$_vault_module_dir/completions.bash"
    # shellcheck source=completions.zsh
    [ -r "$_vault_module_dir/completions.zsh" ] && . "$_vault_module_dir/completions.zsh"
    ;;
esac

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

unset _vault_module_file _vault_module_dir