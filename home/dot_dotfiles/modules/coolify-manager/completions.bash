# Bash tab completions for the coolify-manager module helpers.
#
# Sourced from ~/.dotfiles/modules/coolify-manager/completions.bash
# (interactive shells only). Resource names/uuids are resolved live by the
# Coolify CLI, so this completes the selector prefixes rather than the values.

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

# <command> id=<uuid> | name=<name> | tag=<tag>
_coolify_selector_completion() {
  local cur prev words cword
  _get_comp_words_by_ref cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W 'id= name= tag=' -- "$cur") )
  fi
}
complete -F _coolify_selector_completion \
  cfa cfap cai \
  coolify_find_app coolify_find_app_path coolify_app_info
