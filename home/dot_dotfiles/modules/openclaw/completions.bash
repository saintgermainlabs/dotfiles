# Bash tab completions for the openclaw module helpers.
#
# Sourced from ~/.dotfiles/modules/openclaw/completions.bash (interactive
# shells only). Skills/plugins are completed live from the remote container,
# so this is deliberately limited to local, fast candidates.

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

# oc <flags|subcommand>
_oc_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W '-t --tty -h --help skills plugins devices' -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _oc_completion oc

# Local config destinations for download/upload.
complete -o bashdefault -o default oc_config_put oc_config_get
