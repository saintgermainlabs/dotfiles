# Zsh tab completions for the coolify-manager module helpers.
#
# Sourced from ~/.dotfiles/modules/coolify-manager/completions.zsh
# (interactive shells only). Resource names/uuids are resolved live by the
# Coolify CLI, so this completes the selector prefixes rather than the values.

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

# <command> id=<uuid> | name=<name> | tag=<tag>
_coolify_selector() {
  _values -S '=' 'selector' \
    'id[resource UUID]' \
    'name[resource name]' \
    'tag[resource tag]'
}
compdef _coolify_selector \
  cfa cfap cai \
  coolify_find_app coolify_find_app_path coolify_app_info
