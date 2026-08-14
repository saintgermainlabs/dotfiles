# Zsh tab completions for the hermes-v2 / Hermes Gate helpers.
#
# Sourced from ~/.dotfiles/modules/hermes-v2/completions.zsh (interactive
# shells only).

if [ -z "${ZSH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

if ! (( $+functions[compdef] )); then
  autoload -Uz compinit
  compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
fi

_hg() {
  _arguments -s : \
    '1:command:(-h --help rebuild update stop)' && return
}
compdef _hg hg hermes_gate
