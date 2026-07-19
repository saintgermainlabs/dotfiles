#!/usr/bin/env bash
# Build a shell-env plaintext file from KEY=VALUE pairs and/or named env vars.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-env-plaintext.sh -o PLAINTEXT [OPTIONS]

Write shell export lines to PLAINTEXT from one or more sources.

Options:
  -f FILE       Read KEY=VALUE or export KEY=VALUE lines from FILE (repeatable)
  VAR           Read value from the current environment variable VAR
  KEY=VALUE     Use an explicit pair from the argument list

Examples:
  build-env-plaintext.sh -o /tmp/env.txt COOLIFY_API_TOKEN GEMINI_API_KEY
  build-env-plaintext.sh -o /tmp/env.txt -f ~/.dotfiles/dot_env/.env
  build-env-plaintext.sh -o /tmp/env.txt COOLIFY_URL="https://example.com"
EOF
}

OUT=""
declare -a FILES=()
declare -a ENTRIES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -o)
      OUT="${2:-}"
      shift 2
      ;;
    -f)
      FILES+=("${2:-}")
      shift 2
      ;;
    *)
      ENTRIES+=("$1")
      shift
      ;;
  esac
done

if [ -z "${OUT}" ]; then
  usage >&2
  exit 1
fi

python3 - "${OUT}" "${FILES[@]}" -- "${ENTRIES[@]}" <<'PY'
import os
import re
import sys

out_path = sys.argv[1]
files = []
entries = []
mode = "files"
for arg in sys.argv[2:]:
    if arg == "--":
        mode = "entries"
        continue
    if mode == "files":
        files.append(arg)
    else:
        entries.append(arg)

pairs: list[tuple[str, str]] = []

export_re = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$')

def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value

def add_pair(key: str, value: str) -> None:
    key = key.strip()
    if not key:
        raise SystemExit("Empty variable name is not allowed")
    for idx, (existing_key, _) in enumerate(pairs):
        if existing_key == key:
            pairs[idx] = (key, value)
            return
    pairs.append((key, value))

for path in files:
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = export_re.match(line)
            if not match:
                raise SystemExit(f"Invalid env line in {path}: {line}")
            add_pair(match.group(1), unquote(match.group(2)))

for entry in entries:
    if "=" in entry:
        key, value = entry.split("=", 1)
        add_pair(key, unquote(value))
    else:
        key = entry
        if key not in os.environ:
            raise SystemExit(f"Environment variable not set: {key}")
        add_pair(key, os.environ[key])

if not pairs:
    raise SystemExit("No environment variables provided")

lines = [f'export {key}="{value.replace("\\", "\\\\").replace("\"", "\\\"")}"' for key, value in pairs]
with open(out_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY

echo "Wrote plaintext env to ${OUT} (${#ENTRIES[@]} entries, ${#FILES[@]} file(s))"
