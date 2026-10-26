#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <file.yaml> [OPTIONS]

Options:
  -k, --key <name>        Count occurrences of a specific node/key name
  -i, --indent <spaces>   Count keys with specific indentation (number of spaces)
  -l, --level <depth>     Count keys at specific hierarchy depth (0=root, 1=child, etc.)
  -a, --all               Count total nodes (default)
  -h, --help              Show this help message
EOF
  exit 1
}

# Ensure yq is installed
if ! command -v yq &>/dev/null; then
  echo "Error: 'yq' is required. Install it via 'brew install yq' or 'sudo snap install yq'." >&2
  exit 1
fi

FILE=""
MODE="all"
VALUE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--key)
      MODE="key"
      VALUE="$2"
      shift 2
      ;;
    -i|--indent)
      MODE="indent"
      VALUE="$2"
      shift 2
      ;;
    -l|--level)
      MODE="level"
      VALUE="$2"
      shift 2
      ;;
    -a|--all)
      MODE="all"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
      fi
      ;;
  esac
done

[[ -z "$FILE" || ! -f "$FILE" ]] && usage

case "$MODE" in
  all)
    count=$(yq '.. | select(. != null) | length' "$FILE" | awk '{s+=$1} END {print s}')
    echo "Total node count in $(basename "$FILE"): $count"
    ;;
  key)
    count=$(yq ".. | select(has(\"$VALUE\")) | .\"$VALUE\" | length" "$FILE" | awk '{s+=$1} END {print (s=="")?0:s}')
    echo "Nodes matching key '$VALUE' in $(basename "$FILE"): $count"
    ;;
  level)
    # Counts keys at hierarchical depth $VALUE (0 = root level keys)
    path_pattern=""
    for ((j=0; j<VALUE; j++)); do path_pattern="${path_pattern}.[]"; done
    count=$(yq "${path_pattern} | keys | length" "$FILE" 2>/dev/null | awk '{s+=$1} END {print (s=="")?0:s}')
    echo "Keys at depth $VALUE in $(basename "$FILE"): $count"
    ;;
  indent)
    # Indentation in spaces: regex checks lines starting with exact spaces followed by a YAML key
    count=$(grep -Ec "^[ ]{${VALUE}}[a-zA-Z0-9_-]+:" "$FILE" || true)
    echo "Keys with $VALUE spaces indentation in $(basename "$FILE"): $count"
    ;;
esac