#!/usr/bin/env bash
set -euo pipefail

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HERMES_GATE_DIR="${HERMES_GATE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/hermes-gate}"
HERMES_GATE_REPO="${HERMES_GATE_REPO:-https://github.com/LehaoLin/hermes-gate.git}"

if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/hermes-gate/environment" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${XDG_CONFIG_HOME:-$HOME/.config}/hermes-gate/environment"
  set +a
fi

missing=()
for command_name in docker git ssh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]})); then
  printf 'Missing required commands: %s\n' "${missing[*]}" >&2
  exit 1
fi

if [ -x "${HERMES_GATE_DIR}/run.sh" ]; then
  printf 'Hermes Gate already cloned at %s\n' "$HERMES_GATE_DIR"
else
  if [ -e "$HERMES_GATE_DIR" ]; then
    printf 'Path exists but is not a Hermes Gate checkout: %s\n' "$HERMES_GATE_DIR" >&2
    exit 1
  fi
  printf 'Cloning %s\n' "$HERMES_GATE_REPO"
  mkdir -p "$(dirname "$HERMES_GATE_DIR")"
  git clone "$HERMES_GATE_REPO" "$HERMES_GATE_DIR"
fi

printf 'All dependencies are installed.\n'
printf 'Enable modules.hermes-v2 in modules.toml, then run: chezmoi apply\n'
printf 'Or source directly:\n\n'
printf 'source "%s/module.sh"\n' "$module_dir"
printf '\nThen try: hg_status\n'
printf 'First TUI start (builds the image): hg\n'
