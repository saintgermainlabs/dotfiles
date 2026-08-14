# Bash tab completions for the hermes-v2 / Hermes Gate helpers.
#
# Sourced from ~/.dotfiles/modules/hermes-v2/completions.bash (interactive
# shells only).

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

_hg_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W '-h --help rebuild update stop' -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _hg_completion hg hermes_gate
