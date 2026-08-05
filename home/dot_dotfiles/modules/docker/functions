# Docker helpers — sourced when the docker module is enabled.

# List running containers with name, status, and ports.
cps() {
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Open a shell (or run a command) inside a container.
# Usage: dsh <container> [command]
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
drun() {
  if [ "$#" -lt 1 ]; then
    printf 'Usage: drun <image> [command]\n' >&2
    return 2
  fi
  docker run --rm -it "$@"
}

# Show docker disk usage, then optionally prune.
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