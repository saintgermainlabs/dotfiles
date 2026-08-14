# Zsh tab completions for the hashicorp-vault module helpers.
#
# Sourced from ~/.dotfiles/modules/hashicorp-vault/completions.zsh
# (interactive shells only). KV paths and roles are resolved against the
# Vault server, so this is deliberately limited to local candidates.

if [ -z "${ZSH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

# Initialize the completion system (idempotent).
if ! (( $+functions[compdef] )); then
  autoload -Uz compinit
  compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
fi

# vault_encrypt_file <in> <out> [key] / vault_decrypt_file <in> <out> [key]
compdef _files vault_encrypt_file vault_decrypt_file
