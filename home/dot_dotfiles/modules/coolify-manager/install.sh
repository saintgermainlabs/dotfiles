#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
missing=()

for command_name in jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]})); then
  printf 'Missing required commands: %s\n' "${missing[*]}" >&2
  printf 'Install jq (apt/mise/brew), then re-run.\n' >&2
  exit 1
fi

if ! command -v coolify >/dev/null 2>&1; then
  printf 'coolify CLI not found.\n'
  printf 'Install with:\n\n'
  printf '  curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash\n\n'
  printf 'Then authenticate against your instance:\n\n'
  printf '  coolify context add -d default https://coolify.example.com <api-token>\n'
  printf '  coolify context verify\n\n'
  exit 1
fi

printf 'All dependencies are installed.\n'
printf 'Enable modules.coolify-manager in home/.chezmoidata/modules.toml, then run: chezmoi apply\n'
printf 'Or source directly:\n\n'
printf 'source "%s/module.sh"\n' "$module_dir"
printf '\nThen try:\n'
printf '  coolify_find_app name=openclaw\n'
printf '  coolify_find_app_path name=openclaw\n'
printf '  coolify_app_info name=openclaw\n'
