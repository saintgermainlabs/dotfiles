#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
missing=()

for command_name in vault jq base64; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]})); then
  printf 'Missing required commands: %s\n' "${missing[*]}" >&2
  printf '%s\n' \
    'Install HashiCorp Vault CLI and jq, then run this check again.' >&2
  exit 1
fi

printf 'All dependencies are installed.\n'
printf 'Add this line to ~/.bashrc or ~/.zshrc:\n\n'
printf 'source "%s/module.sh"\n' "$module_dir"
printf '\nThen restart the shell or run the source command directly.\n'

