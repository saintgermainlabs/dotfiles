#!/bin/bash

## @module docker
## @title Docker
## @description Provides Docker container management, inspection, and diagnostic helpers.
## @category Containers
## @requires docker
## @tags docker container containers images compose
## @source functions.sh

# shellcheck shell=bash

if [ -n "${BASH_VERSION:-}" ]; then
  _docker_module_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  # shellcheck disable=SC2296
  _docker_module_file="${(%):-%N}"
else
  _docker_module_file="$0"
fi

_docker_module_dir="$(
  CDPATH= cd -- "$(dirname -- "$_docker_module_file")" && pwd
)"

# Source remote helpers if available
if [ -f "${_docker_module_dir}/../../remote/remote_helpers.sh" ]; then
  # shellcheck disable=SC1091
  . "${_docker_module_dir}/../../remote/remote_helpers.sh"
fi

# shellcheck source=functions.sh
. "${_docker_module_dir}/functions.sh"

# Interactive-only tab completions.
case $- in
  *i*)
    # shellcheck source=completions.bash
    [ -r "${_docker_module_dir}/completions.bash" ] && . "${_docker_module_dir}/completions.bash"
    # shellcheck source=completions.zsh
    [ -r "${_docker_module_dir}/completions.zsh" ] && . "${_docker_module_dir}/completions.zsh"
    ;;
esac

unset _docker_module_file _docker_module_dir
