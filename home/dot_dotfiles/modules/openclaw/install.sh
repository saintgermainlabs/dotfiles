#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
missing=()

for command_name in ssh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]})); then
  printf 'Missing required commands: %s\n' "${missing[*]}" >&2
  exit 1
fi

printf 'All dependencies are installed.\n'
printf 'Enable modules.openclaw in modules.toml, then run: chezmoi apply\n'
printf 'Or source directly:\n\n'
printf 'source "%s/module.sh"\n' "$module_dir"
printf '\nThen try: oc_status\n'
