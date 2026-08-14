# Zsh tab completions for the openclaw module helpers.
#
# Sourced from ~/.dotfiles/modules/openclaw/completions.zsh (interactive
# shells only). Skills/plugins are completed live from the remote container,
# so this is deliberately limited to local, fast candidates.

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

# oc <flags|subcommand>
_oc() {
  _arguments -s : \
    '1:command:(-t --tty -h --help skills plugins devices)' && return
}
compdef _oc oc

# Local config destinations for download/upload.
compdef _files oc_config_put oc_config_get
