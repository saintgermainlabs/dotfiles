# Docker helpers — sourced when the docker module is enabled.

# List running containers with name, status, and ports.
## @category Docker
## @description List running containers with name, status, and ports in a table format
## @usage cps
## @requires docker
## @see docker-ps(1)
cps() {
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Open a shell (or run a command) inside a container.
# Usage: dsh <container> [command]
## @category Docker
## @description Open a shell or run a command inside a Docker container
## @usage dsh <container> [command]
## @arg $1 string The container name or ID to execute commands in
## @arg $@ string Optional command to run in the container (defaults to bash or sh)
## @exitcode 0 If the command executes successfully
## @exitcode 2 If incorrect number of arguments provided
## @requires docker
## @example dsh my-container
## @example dsh my-container ls -la
## @see docker-exec(1)
dsh() {
  if [ "$#" -lt 1 ]; then
    printf 'Usage: dsh <container> [command]\n' >&2
    return 2
  fi
  local container="$1"
  shift
  if [ "$#" -gt 0 ]; then
    docker exec -it "$container" "$@"
  elif docker exec "$container" test -x /bin/bash 2>/dev/null; then
    docker exec -it "$container" /bin/bash
  else
    docker exec -it "$container" /bin/sh
  fi
}

# Run an interactive container and remove it on exit.
# Usage: drun <image> [command]
## @category Docker
## @description Run an interactive Docker container and remove it when it exits
## @usage drun <image> [command]
## @arg $1 string The Docker image to run
## @arg $@ string Optional command to run in the container
## @exitcode 0 If the container runs successfully
## @exitcode 2 If incorrect number of arguments provided
## @requires docker
## @example drun ubuntu:latest
## @example drun alpine:latest sh
## @see docker-run(1)
drun() {
  if [ "$#" -lt 1 ]; then
    printf 'Usage: drun <image> [command]\n' >&2
    return 2
  fi
  docker run --rm -it "$@"
}

# Show docker disk usage, then optionally prune.
## @category Docker
## @description Show Docker disk usage statistics and optionally prune unused data
## @usage dprune
## @stdin Prompts for confirmation before pruning
## @requires docker
## @example dprune
## @see docker-system(1)
dprune() {
  docker system df
  printf 'Run Docker system prune? [y/N] '
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes|YES) docker system prune ;;
    *) printf 'Cancelled.\n' ;;
  esac
}


# @name        container_id
# @category    docker
# @summary     Find a Docker container ID using app.name and app.component labels.
# @usage       container_id <app-name> <component>
# @arg         app-name     Value of the Docker "app.name" label.
# @arg         component    Value of the Docker "app.component" label.
# @returns     Docker container ID of the matching running container.
# @example     container_id openclaw application
# @example     container_id openclaw browser
# @example     container_id openclaw tailscale-sidecar
# @example     docker logs -f "$(container_id openclaw application)"
# @example     docker exec -it "$(container_id openclaw application)" bash
# @description
#   Finds a running Docker container by matching both the app.name and
#   app.component labels.
#
#   Exactly one running container must match. If no container is found,
#   the function returns 1. If multiple containers match, it prints the
#   matching containers and returns 2.
container_id() {
    local app_name="$1"
    local component="$2"

    if [[ -z "$app_name" || -z "$component" ]]; then
        echo "Usage: container_id <app-name> <component>" >&2
        return 1
    fi

    local id
    id=$(docker ps -q \
        --filter "label=app.name=${app_name}" \
        --filter "label=app.component=${component}")

    if [[ -z "$id" ]]; then
        echo "No running container found: app.name=${app_name}, app.component=${component}" >&2
        return 1
    fi

    if [[ $(wc -l <<< "$id") -gt 1 ]]; then
        echo "Multiple containers matched: app.name=${app_name}, app.component=${component}" >&2

        docker ps \
            --filter "label=app.name=${app_name}" \
            --filter "label=app.component=${component}" \
            --format '{{.ID}}  {{.Names}}' >&2

        return 2
    fi

    printf '%s\n' "$id"
}

## @category Docker
## @description Find a running Docker container by app.name and app.component labels.
## @usage find_container <app> <component> [id|name|all]
## @arg $1 string Value of the Docker app.name label
## @arg $2 string Value of the Docker app.component label
## @arg $3 string Optional output mode: id (default), name, or all
## @stdout Container ID, name, or full docker inspect JSON depending on output mode
## @stderr Usage and match errors
## @exitcode 0 If exactly one container matches
## @exitcode 1 If no container matches or docker fails
## @exitcode 2 If usage is invalid or multiple containers match
## @requires docker
## @example find_container openclaw application
## @example find_container openclaw application name
## @example find_container openclaw application all
## @see docker-ps(1)
## @see docker-inspect(1)
## @tags docker container labels find
find_container() {
  local app_name="$1"
  local component="$2"
  local output="${3:-id}"
  local ids id count

  if [ -z "$app_name" ] || [ -z "$component" ]; then
    printf 'Usage: find_container <app> <component> [id|name|all]\n' >&2
    return 2
  fi

  case "$output" in
    id|name|all) ;;
    *)
      printf 'Usage: find_container <app> <component> [id|name|all]\n' >&2
      printf 'Unknown output mode: %s\n' "$output" >&2
      return 2
      ;;
  esac

  if ! command -v docker >/dev/null 2>&1; then
    printf 'find_container: required command not found: docker\n' >&2
    return 1
  fi

  ids="$(
    docker ps -q \
      --filter "label=app.name=${app_name}" \
      --filter "label=app.component=${component}"
  )" || return 1

  if [ -z "$ids" ]; then
    printf 'No running container found: app.name=%s, app.component=%s\n' \
      "$app_name" "$component" >&2
    return 1
  fi

  count="$(printf '%s\n' "$ids" | grep -c .)"
  if [ "$count" -gt 1 ]; then
    printf 'Multiple containers matched: app.name=%s, app.component=%s\n' \
      "$app_name" "$component" >&2
    docker ps \
      --filter "label=app.name=${app_name}" \
      --filter "label=app.component=${component}" \
      --format '{{.ID}}  {{.Names}}' >&2
    return 2
  fi

  id="$ids"

  case "$output" in
    id)
      printf '%s\n' "$id"
      ;;
    name)
      docker inspect --format '{{.Name}}' "$id" | sed 's#^/##'
      ;;
    all)
      docker inspect "$id"
      ;;
  esac
}

## @internal
## @category Docker
## @description Parse an app.component selector into app and component parts.
## @usage _container_parse_app_component <app.component>
## @arg $1 string Selector in app.component format (split on the first dot)
## @stdout Sets _CONTAINER_APP and _CONTAINER_COMPONENT
## @exitcode 0 If parsing succeeds
## @exitcode 2 If the selector is missing or invalid
_container_parse_app_component() {
  local selector="$1"

  _CONTAINER_APP=""
  _CONTAINER_COMPONENT=""

  if [ -z "$selector" ]; then
    printf 'Expected app.component format\n' >&2
    return 2
  fi

  case "$selector" in
    *.*)
      _CONTAINER_APP="${selector%%.*}"
      _CONTAINER_COMPONENT="${selector#*.}"
      ;;
    *)
      printf 'Expected app.component format, got: %s\n' "$selector" >&2
      return 2
      ;;
  esac

  if [ -z "$_CONTAINER_APP" ] || [ -z "$_CONTAINER_COMPONENT" ]; then
    printf 'Expected app.component format, got: %s\n' "$selector" >&2
    return 2
  fi
}

## @category Docker
## @description Resolve an app.component selector to a container id, name, or inspect JSON.
## @usage container_resolve <app.component> [id|name|all]
## @arg $1 string Selector in app.component format, e.g. openclaw.tailscale-sidecar
## @arg $2 string Optional output mode passed to find_container (default: id)
## @stdout Container id, name, or inspect JSON
## @exitcode 0 If exactly one container matches
## @exitcode 1 If lookup fails
## @exitcode 2 If usage or selector format is invalid
## @requires docker
## @example container_resolve openclaw.application
## @example container_resolve openclaw.tailscale-sidecar name
## @see find_container
container_resolve() {
  local selector="$1"
  local output="${2:-id}"

  if [ -z "$selector" ]; then
    printf 'Usage: container_resolve <app.component> [id|name|all]\n' >&2
    return 2
  fi

  _container_parse_app_component "$selector" || return $?
  find_container "$_CONTAINER_APP" "$_CONTAINER_COMPONENT" "$output"
}

## @category Docker
## @description Open an interactive /bin/sh shell in a container identified by app.component labels.
## @usage container_sh <app.component>
## @arg $1 string Selector in app.component format, e.g. openclaw.tailscale-sidecar
## @exitcode 0 If the shell session exits successfully
## @exitcode 1 If the container cannot be found
## @exitcode 2 If usage or selector format is invalid
## @requires docker
## @example container_sh openclaw.application
## @example container_sh openclaw.tailscale-sidecar
## @see find_container
## @see docker-exec(1)
container_sh() {
  local selector="$1"
  local name

  if [ -z "$selector" ]; then
    printf 'Usage: container_sh <app.component>\n' >&2
    return 2
  fi

  _container_parse_app_component "$selector" || return $?
  name="$(find_container "$_CONTAINER_APP" "$_CONTAINER_COMPONENT" name)" || return $?
  docker exec -it "$name" sh
}

## @category Docker
## @description Run a command in a container identified by app.component labels.
## @usage container_exec <app.component> <command> [args...]
## @arg $1 string Selector in app.component format, e.g. openclaw.application
## @arg $@ string Command and arguments to run inside the container
## @exitcode 0 If the command succeeds
## @exitcode 1 If the container cannot be found
## @exitcode 2 If usage or selector format is invalid
## @requires docker
## @example container_exec openclaw.application ls -la
## @see find_container
## @see docker-exec(1)
container_exec() {
  local selector="$1"
  local name

  if [ "$#" -lt 2 ]; then
    printf 'Usage: container_exec <app.component> <command> [args...]\n' >&2
    return 2
  fi

  selector="$1"
  shift

  _container_parse_app_component "$selector" || return $?
  name="$(find_container "$_CONTAINER_APP" "$_CONTAINER_COMPONENT" name)" || return $?
  docker exec -it "$name" "$@"
}

## @category Docker
## @description Restart a container identified by app.component labels.
## @usage container_restart <app.component>
## @arg $1 string Selector in app.component format, e.g. openclaw.tailscale-sidecar
## @exitcode 0 If the container restarts successfully
## @exitcode 1 If the container cannot be found or restart fails
## @exitcode 2 If usage or selector format is invalid
## @requires docker
## @example container_restart openclaw.application
## @example container_restart openclaw.tailscale-sidecar
## @see find_container
## @see docker-restart(1)
container_restart() {
  local selector="$1"
  local name

  if [ -z "$selector" ]; then
    printf 'Usage: container_restart <app.component>\n' >&2
    return 2
  fi

  _container_parse_app_component "$selector" || return $?
  name="$(find_container "$_CONTAINER_APP" "$_CONTAINER_COMPONENT" name)" || return $?
  docker restart "$name"
}
