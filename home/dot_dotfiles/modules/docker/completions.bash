# Bash tab completions for the docker module helpers.
#
# Sourced from ~/.dotfiles/modules/docker/completions.bash (interactive shells
# only). Container/image/selector lookups hit the local docker daemon, which
# is fast enough for tab completion.

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
if ! command -v docker >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# --- candidate sources -----------------------------------------------------

__df_docker_containers() {
  docker ps --format '{{.Names}}' 2>/dev/null
}

__df_docker_images() {
  docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null
}

__df_docker_apps() {
  docker ps --format '{{.Label "app.name"}}' 2>/dev/null | grep -v '^$' | sort -u
}

__df_docker_app_components() {
  docker ps --format '{{.Label "app.name"}}.{{.Label "app.component"}}' 2>/dev/null | grep -v '\.$\|^\.' | sort -u
}

__df_docker_components_for() {
  docker ps --filter "label=app.name=$1" --format '{{.Label "app.component"}}' 2>/dev/null | grep -v '^$' | sort -u
}

# --- completions -----------------------------------------------------------

# dsh <container> [command]
_dsh_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(__df_docker_containers)" -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _dsh_completion dsh

# drun <image> [command]
_drun_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(__df_docker_images)" -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _drun_completion drun

# find_container <app> <component> [id|name|all]
# container_id <app> <component>
_find_container_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  case "$cword" in
    1) COMPREPLY=( $(compgen -W "$(__df_docker_apps)" -- "$cur") ) ;;
    2) COMPREPLY=( $(compgen -W "$(__df_docker_components_for "$prev")" -- "$cur") ) ;;
    3) COMPREPLY=( $(compgen -W 'id name all' -- "$cur") ) ;;
  esac
}
complete -o bashdefault -o default -F _find_container_completion find_container container_id

# container_resolve <app.component> [id|name|all]
# container_sh <app.component>
# container_exec <app.component> <command> [args...]
# container_restart <app.component>
_container_app_component_completion() {
  local cur prev words cword
  _get_comp_words_by_ref -n =: cur prev words cword || return
  if [ "$cword" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(__df_docker_app_components)" -- "$cur") )
  elif [ "$cword" -eq 2 ]; then
    COMPREPLY=( $(compgen -W 'id name all' -- "$cur") )
  fi
}
complete -o bashdefault -o default -F _container_app_component_completion \
  container_resolve container_sh container_exec container_restart
