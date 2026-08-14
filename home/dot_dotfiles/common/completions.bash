# Bash tab completions for the common aliases and functions.
#
# Sourced from ~/.dotfiles/common/completions.bash. Self-guarding: safe to
# source unconditionally, but only interactive bash shells install anything.

if [ -z "${BASH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

# The completers below rely on bash-completion helpers loaded in common/shell.
if ! declare -F _get_comp_words_by_ref >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# Generic alias delegate.
#
#   _df_alias_complete <alias> <completer> <leading words...>
#
# Registers tab completion for <alias> by rewriting the command line to start
# with <leading words...> before handing control to <completer>. This is what
# lets `gcm` complete exactly like `git commit -m`.
# ---------------------------------------------------------------------------
_df_alias_complete() {
  local alias_name="$1" func="$2"; shift 2
  local -a lead=("$@")
  local wrapper="_df_wrap_${alias_name}"
  local quoted="" w
  for w in "${lead[@]}"; do
    quoted+="'${w}' "
  done
  # shellcheck disable=SC2086
  eval "function ${wrapper} {
    local cur prev words cword _st
    _get_comp_words_by_ref -n =: cur prev words cword || return
    COMP_WORDS=( ${quoted}\"\${words[@]:1}\" )
    COMP_CWORD=\$(( cword + ${#lead[@]} - 1 ))
    ${func}
    _st=\$?
    return \$_st
  }"
  complete -o bashdefault -o default -F "${wrapper}" "${alias_name}"
}

# --- git aliases -----------------------------------------------------------
if command -v git >/dev/null 2>&1 && [ -r /usr/share/bash-completion/completions/git ]; then
  # shellcheck disable=SC1091
  . /usr/share/bash-completion/completions/git
  __git_complete g __git_main
  __git_complete gcm _git_commit
  __git_complete gcam _git_commit
  __git_complete gcad _git_commit
fi

# --- GitHub CLI aliases ----------------------------------------------------
if command -v gh >/dev/null 2>&1 && [ -r /usr/share/bash-completion/completions/gh ]; then
  # shellcheck disable=SC1091
  . /usr/share/bash-completion/completions/gh
  _df_alias_complete ghpr __start_gh gh pr view --web
  _df_alias_complete ghprs __start_gh gh pr list
  _df_alias_complete ghrepo __start_gh gh repo view --web
fi

# --- docker alias ----------------------------------------------------------
if command -v docker >/dev/null 2>&1 && [ -r /usr/share/bash-completion/completions/docker ]; then
  # shellcheck disable=SC1091
  . /usr/share/bash-completion/completions/docker
  # cobra's __start_docker uses ${words[0]} for the binary, so `d` works as-is.
  complete -o default -F __start_docker d
fi

# --- simple file / directory completions -----------------------------------
# n: Neovim over a file, directory, or the current directory.
complete -o bashdefault -o default n
# mkcd: directories only.
complete -o dirnames mkcd
# extract / compress / decompress: archive files.
complete -o bashdefault -o default extract compress decompress
# venv: accepts a hidden env directory; plain file completion is fine.
complete -o bashdefault -o default venv
