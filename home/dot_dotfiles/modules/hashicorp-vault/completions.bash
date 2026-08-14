# Bash tab completions for the hashicorp-vault module helpers.
#
# Sourced from ~/.dotfiles/modules/hashicorp-vault/completions.bash
# (interactive shells only). KV paths and roles are resolved against the
# Vault server, so this is deliberately limited to local candidates.

if [ -z "${BASH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

if ! declare -F _get_comp_words_by_ref >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# vault_encrypt_file <in> <out> [key] / vault_decrypt_file <in> <out> [key]
complete -o bashdefault -o default vault_encrypt_file vault_decrypt_file
