# Zsh tab completions for the docker module helpers.
#
# Sourced from ~/.dotfiles/modules/docker/completions.zsh (interactive shells
# only). Container/image/selector lookups hit the local docker daemon, which
# is fast enough for tab completion.

if [ -z "${ZSH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

# Initialize the completion system (idempotent).
if ! (( $+functions[compdef] )); then
  autoload -Uz compinit
  compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
fi

# --- candidate sources -----------------------------------------------------

__df_docker_running_containers() {
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
_dsh() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -s : \
    '1:running container:->containers' \
    '*::command:' && ret=0
  case $state in
    containers)
      local expl
      _wanted containers expl 'running container' compadd -- $(__df_docker_running_containers) && ret=0
      ;;
  esac
  return ret
}
compdef _dsh dsh

# drun <image> [command]
_drun() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -s : \
    '1:image:->images' \
    '*::command:' && ret=0
  case $state in
    images)
      local expl
      _wanted images expl 'docker image' compadd -- $(__df_docker_images) && ret=0
      ;;
  esac
  return ret
}
compdef _drun drun

# find_container <app> <component> [id|name|all]
# container_id <app> <component>
_find_container() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -s : \
    '1:app:->apps' \
    '2:component:->components' \
    '3:mode:(id name all)' && ret=0
  case $state in
    apps)
      local expl
      _wanted apps expl 'docker app' compadd -- $(__df_docker_apps) && ret=0
      ;;
    components)
      local expl
      _wanted components expl 'docker component' compadd -- $(__df_docker_components_for "$line[1]") && ret=0
      ;;
  esac
  return ret
}
compdef _find_container find_container container_id

# container_resolve <app.component> [id|name|all]
_container_resolve() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -s : \
    '1:app.component:->selector' \
    '2:mode:(id name all)' && ret=0
  case $state in
    selector)
      local expl
      _wanted selector expl 'app.component selector' compadd -- $(__df_docker_app_components) && ret=0
      ;;
  esac
  return ret
}
compdef _container_resolve container_resolve

# container_sh <app.component>
# container_exec <app.component> <command> [args...]
# container_restart <app.component>
_container_selector_cmd() {
  local curcontext="$curcontext" state line
  integer ret=1
  typeset -A opt_args
  _arguments -s : \
    '1:app.component:->selector' \
    '*::command:' && ret=0
  case $state in
    selector)
      local expl
      _wanted selector expl 'app.component selector' compadd -- $(__df_docker_app_components) && ret=0
      ;;
  esac
  return ret
}
compdef _container_selector_cmd container_sh container_exec container_restart
