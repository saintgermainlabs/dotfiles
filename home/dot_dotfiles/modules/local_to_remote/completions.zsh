# Zsh tab completions for the local_to_remote module helpers.
#
# Sourced from ~/.dotfiles/modules/local_to_remote/completions.zsh
# (interactive shells only). Approved file keys are read straight from the
# local config file; everything else is local file or function completion.

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

# Approved file keys from LTR_ALLOWED_FILES (no network involved).
__df_ltr_keys() {
  source "${LOCAL_TO_REMOTE_CONFIG:-$HOME/.config/local_to_remote/config.sh}" >/dev/null 2>&1
  print -rl -- "${(k)LTR_ALLOWED_FILES}"
}

# remote_edit <key> / remote_show <key> / remote_backup_file <key>
_ltr_key() {
  compadd -- $(__df_ltr_keys)
}
compdef _ltr_key remote_edit remote_show remote_backup_file

# rfunc <function> [args...] / r <function> [args...]
_rfunc() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -C -s : \
    '1:function:->funcs' \
    '*::argument:' && ret=0
  case $state in
    funcs)
      local expl
      _wanted funcs expl 'shell function' compadd -- ${(k)functions} && ret=0
      ;;
  esac
  return ret
}
compdef _rfunc rfunc r

# File paths for upload/download.
compdef _files remote_upload remote_download
