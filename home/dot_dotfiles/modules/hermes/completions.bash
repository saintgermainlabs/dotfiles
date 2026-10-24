# Bash tab completions for the hermes module helpers.
#
# Sourced from ~/.dotfiles/modules/hermes/completions.bash (interactive
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

# hm <flags|subcommand>
_hm_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W '-t --tty -h --help skills plugins gateway config profile status doctor pairing' -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _hm_completion hm

_hm_config_edit_completion() {
  local cur prev
  _get_comp_words_by_ref cur prev || return
  case "$prev" in
    --editor)
      COMPREPLY=( $(compgen -W 'sublime nano vscode' -- "$cur") )
      return
      ;;
  esac
  COMPREPLY=( $(compgen -W '--editor' -- "$cur") )
}
complete -o bashdefault -o default -F _hm_config_edit_completion hm_config_edit

# Local config destinations for download/upload.
complete -o bashdefault -o default hm_config_put hm_config_get

# hwedit [--dry-run|--list] <file>  (files come from the remote container; flags only here)
complete -W '--dry-run --list --help' hwedit
