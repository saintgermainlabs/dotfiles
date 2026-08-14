# Bash tab completions for the local_to_remote module helpers.
#
# Sourced from ~/.dotfiles/modules/local_to_remote/completions.bash
# (interactive shells only). Approved file keys are read straight from the
# local config file; everything else is local file or function completion.

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

# Approved file keys from LTR_ALLOWED_FILES (no network involved).
__df_ltr_keys() {
  source "${LOCAL_TO_REMOTE_CONFIG:-$HOME/.config/local_to_remote/config.sh}" >/dev/null 2>&1
  printf '%s\n' "${!LTR_ALLOWED_FILES[@]}"
}

# remote_edit <key> / remote_show <key> / remote_backup_file <key>
_ltr_key_completion() {
  local cur prev words cword
  _get_comp_words_by_ref cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(__df_ltr_keys)" -- "$cur") )
  fi
}
complete -F _ltr_key_completion remote_edit remote_show remote_backup_file

# rfunc <function> [args...] / r <function> [args...]
_rfunc_completion() {
  local cur prev words cword
  _get_comp_words_by_ref cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(declare -F | awk '{print $3}')" -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _rfunc_completion rfunc r

# File paths for upload/download.
complete -o bashdefault -o default remote_upload remote_download
