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
