# Zsh tab completions for the hermes module helpers.
#
# Sourced from ~/.dotfiles/modules/hermes/completions.zsh (interactive
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

# hm <flags|subcommand>
_hm() {
  _arguments -s : \
    '1:command:(-t --tty -h --help skills plugins gateway config profile status doctor pairing)' && return
}
compdef _hm hm

_hm_config_edit() {
  _arguments -s : \
    '--editor[editor to use]:editor:(sublime nano vscode)'
}
compdef _hm_config_edit hm_config_edit

# Local config destinations for download/upload.
compdef _files hm_config_put hm_config_get
