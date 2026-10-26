# shellcheck shell=bash
#
# Dotfiles loader helpers — sourced first by ~/.bashrc and ~/.zshrc (bash + zsh).
#
#   _df_source <file>        source a file if readable; DEBUG_MODE=1 logs it to stderr
#   _df_load_module <dir>    load a module as declared in <dir>/config.toml [bootstrap]
#
# config.toml schema (all keys optional; arrays may be single- or multi-line;
# '#' comments and "double"/'single' quoted strings are supported, no escapes):
#
#   [bootstrap]
#   env         = ["~/.config/foo/environment"]  # sourced with set -a (exported)
#   files       = ["functions.sh"]               # always, in order
#   interactive = ["aliases.sh"]                 # interactive shells only
#   bash        = ["completions.bash"]           # interactive bash only
#   zsh         = ["completions.zsh"]            # interactive zsh only
#
# Load order is fixed: env -> files -> interactive -> bash|zsh, each list in order.
# Paths: leading ~ and $VAR / ${VAR:-default} are expanded; relative paths resolve
# against the module dir. Missing files are skipped silently (DEBUG_MODE shows nothing).
# Without config.toml: module.sh, else legacy functions.sh, aliases.sh, functions,
# local_to_remote.sh.

_df_source() {
  [ -r "$1" ] || return 0
  [ -n "${DEBUG_MODE:-}" ] && printf 'dotfiles: sourcing %s\n' "$1" >&2
  # shellcheck disable=SC1090
  . "$1"
}

# Print "<key><TAB><value>" for every string in the [bootstrap] table of a TOML file.
_df_bootstrap_entries() {
  awk '
    BEGIN { insec = 0; inarr = 0; key = "" }
    {
      line = $0
      if (!inarr) {
        sub(/^[ \t]+/, "", line)
        if (line == "" || substr(line, 1, 1) == "#") next
        if (substr(line, 1, 1) == "[") { insec = (line ~ /^\[[ \t]*bootstrap[ \t]*\]/); next }
        if (!insec) next
        eq = index(line, "="); if (!eq) next
        key = substr(line, 1, eq - 1); gsub(/[ \t"]/, "", key)
        line = substr(line, eq + 1)
      }
      n = length(line); i = 1
      while (i <= n) {
        c = substr(line, i, 1)
        if (c == "\"" || c == "\047") {
          j = i + 1; s = ""
          while (j <= n && substr(line, j, 1) != c) { s = s substr(line, j, 1); j++ }
          print key "\t" s; i = j + 1; continue
        }
        if (c == "#") break
        if (c == "[") inarr = 1
        if (c == "]") inarr = 0
        i++
      }
    }' "$1"
}

# Resolve one bootstrap path ($1) relative to module dir ($2); prints the result.
_df_bootstrap_path() {
  _dfp_p="$1"
  case "$_dfp_p" in
    *'$('*|*'`'*) printf 'dotfiles: refusing unsafe path %s\n' "$_dfp_p" >&2; unset _dfp_p; return 1 ;;
  esac
  case "$_dfp_p" in
    '~') _dfp_p="$HOME" ;;
    '~/'*) _dfp_p="$HOME/${_dfp_p#\~/}" ;;
  esac
  case "$_dfp_p" in
    *'$'*) eval "_dfp_p=\"$_dfp_p\"" ;;
  esac
  case "$_dfp_p" in
    /*) printf '%s\n' "$_dfp_p" ;;
    *) printf '%s\n' "$2/$_dfp_p" ;;
  esac
  unset _dfp_p
}

_df_load_module() {
  _dfm_dir="${1%/}"
  if [ ! -r "$_dfm_dir/config.toml" ]; then
    if [ -r "$_dfm_dir/module.sh" ]; then
      _df_source "$_dfm_dir/module.sh"
    else
      for _dfm_f in functions.sh aliases.sh functions local_to_remote.sh; do
        _df_source "$_dfm_dir/$_dfm_f"
      done
    fi
    unset _dfm_dir _dfm_f
    return 0
  fi

  _dfm_shell=""
  [ -n "${BASH_VERSION:-}" ] && _dfm_shell=bash
  [ -n "${ZSH_VERSION:-}" ] && _dfm_shell=zsh
  _dfm_inter=0
  case $- in *i*) _dfm_inter=1 ;; esac

  _dfm_entries="$(_df_bootstrap_entries "$_dfm_dir/config.toml")"
  for _dfm_phase in env files interactive "$_dfm_shell"; do
    [ -n "$_dfm_phase" ] || continue
    case "$_dfm_phase" in
      env|files) ;;
      *) [ "$_dfm_inter" = 1 ] || continue ;;
    esac
    while IFS='	' read -r _dfm_k _dfm_v; do
      [ "$_dfm_k" = "$_dfm_phase" ] && [ -n "$_dfm_v" ] || continue
      _dfm_f="$(_df_bootstrap_path "$_dfm_v" "$_dfm_dir")" || continue
      if [ "$_dfm_phase" = env ]; then
        if [ -r "$_dfm_f" ]; then set -a; _df_source "$_dfm_f"; set +a; fi
      else
        _df_source "$_dfm_f"
      fi
    done <<_DF_EOF_
$_dfm_entries
_DF_EOF_
  done
  unset _dfm_dir _dfm_f _dfm_k _dfm_v _dfm_shell _dfm_inter _dfm_entries _dfm_phase
}
