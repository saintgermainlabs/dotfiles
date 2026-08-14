# Zsh tab completions for the common aliases and functions.
#
# Sourced from ~/.dotfiles/common/completions.zsh. Self-guarding: safe to
# source unconditionally, but only interactive zsh shells install anything.

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

# ---------------------------------------------------------------------------
# Generic alias delegate.
#
#   _df_zsh_alias <alias> <completer> <service> [leading words...]
#
# Registers completion for <alias> by rewriting $words/$CURRENT to look like
# `service leading-words...` before calling <completer>. This lets `gcm`
# complete exactly like `git commit -m`.
# ---------------------------------------------------------------------------
_df_zsh_alias() {
  local alias_name="$1" func="$2" service="$3"; shift 3
  local -a lead=("$@")
  local wrapper="_df_zsh_${alias_name}"
  local lead_str="" w
  for w in "${lead[@]}"; do
    lead_str+="${(q)w} "
  done
  eval "function ${wrapper}() {
    local service=${service}
    words=( ${lead_str}\"\${words[@]:1}\" )
    (( CURRENT += ${#lead[@]} ))
    ${func}
  }"
  compdef "${wrapper}" "${alias_name}"
}

# --- git aliases -----------------------------------------------------------
if (( $+functions[_git] )) || { autoload -Uz _git 2>/dev/null; (( $+functions[_git] )); }; then
  _df_zsh_alias g _git git
  _df_zsh_alias gcm _git commit -m
  _df_zsh_alias gcam _git commit -a -m
  _df_zsh_alias gcad _git commit -a --amend
fi

# --- GitHub CLI aliases ----------------------------------------------------
if (( $+functions[_gh] )) || { autoload -Uz _gh 2>/dev/null; (( $+functions[_gh] )); }; then
  _df_zsh_alias ghpr _gh gh pr view --web
  _df_zsh_alias ghprs _gh gh pr list
  _df_zsh_alias ghrepo _gh gh repo view --web
fi

# --- docker alias ----------------------------------------------------------
if (( $+functions[_docker] )) || { autoload -Uz _docker 2>/dev/null; (( $+functions[_docker] )); }; then
  _df_zsh_alias d _docker docker
fi

# --- simple file / directory completions -----------------------------------
# n: Neovim over a file, directory, or the current directory.
compdef _files n
# mkcd: directories only.
compdef _directories mkcd
# extract / compress / decompress: archive files.
compdef _files extract compress decompress
# up: an integer level count, not a filename.
_up() { _message 'number of directory levels to ascend'; }
compdef _up up
