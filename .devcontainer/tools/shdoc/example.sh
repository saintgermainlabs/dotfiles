#!/usr/bin/env bash
# @file shdoc-example
# @brief Tiny example for trying shdoc inside the devcontainer.
# @description
#     Demonstrates shdoc annotations on a shell function.
#     Generate docs with:
#       shdoc .devcontainer/tools/shdoc/example.sh

# @description Print a greeting for the given name.
# @arg $1 string Name to greet
# @stdout A greeting line
# @exitcode 0 Always succeeds
# @example
#   say-hello World
say-hello() {
  local name="${1:-there}"
  printf 'Hello, %s\n' "$name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  say-hello "${1:-devcontainer}"
fi
