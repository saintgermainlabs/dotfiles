#!/usr/bin/env bash
# Repo checks: render every template, syntax-check scripts, parse chezmoidata.
# Run from anywhere: tests/check.sh
# Exits non-zero if any check fails.

set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
home_dir="${repo}/home"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failures=0
checked=0
fail() {
  printf 'FAIL %s\n' "$1" >&2
  failures=$((failures + 1))
}
need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'error: %s is required\n' "$1" >&2
    exit 2
  }
}
need chezmoi
need python3

# 1. Every template must render with the real chezmoi data.
while IFS= read -r -d '' tmpl; do
  rel="${tmpl#"$repo"/}"
  checked=$((checked + 1))
  out="${tmp}/$(printf '%s' "$rel" | tr '/' '_').out"
  if ! chezmoi execute-template --source "$repo" < "$tmpl" > "$out" 2> "${out}.err"; then
    fail "template does not render: ${rel} ($(head -n 1 "${out}.err"))"
  else
    printf '%s\t%s\n' "$rel" "$out" >> "${tmp}/rendered.index"
  fi
done < <(find "$home_dir" -name '*.tmpl' -print0)

# 2. Shell scripts (source files and rendered templates) must parse.
check_shell() {
  local file="$1" label="$2" shell
  shell="bash"
  if head -n 1 "$file" | grep -qE '^#!.*/(sh|dash)([[:space:]]|$)'; then
    shell="sh"
  fi
  checked=$((checked + 1))
  if ! "$shell" -n "$file" 2> "${tmp}/syntax.err"; then
    fail "${shell} -n: ${label} ($(head -n 1 "${tmp}/syntax.err"))"
  fi
}
while IFS= read -r -d '' file; do
  check_shell "$file" "${file#"$repo"/}"
done < <(find "$home_dir" \( -path '*/common/*' -o -path '*/utils/*' \) \
  -type f ! -name '*.tmpl' ! -name '*.md' ! -name '*.zsh' -print0)
# Rendered shell fragments: bash rc, scripts, and partials. zsh is not checked
# here because zsh is not installed on this machine.
if [ -f "${tmp}/rendered.index" ]; then
  while IFS=$'\t' read -r rel out; do
    case "$rel" in
      home/dot_bashrc.tmpl|home/.chezmoiscripts/*|home/.chezmoitemplates/*)
        check_shell "$out" "${rel} (rendered)"
        ;;
    esac
  done < "${tmp}/rendered.index"
fi

# 3. Every chezmoidata file must parse as TOML.
while IFS= read -r -d '' data; do
  checked=$((checked + 1))
  if ! python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$data" 2> "${tmp}/toml.err"; then
    fail "invalid TOML: ${data#"$repo"/} ($(tail -n 1 "${tmp}/toml.err"))"
  fi
done < <(find "$home_dir/.chezmoidata" -name '*.toml' -print0)

# 4. shellcheck, when it is installed.
if command -v shellcheck >/dev/null 2>&1; then
  # The common/ files are bash-compatible and sourced by bash and zsh. The zsh-only
  # completions file is skipped (zsh is not installed here).
  while IFS= read -r -d '' file; do
    checked=$((checked + 1))
    if ! shellcheck -s bash -S error "$file" >/dev/null 2>&1; then
      fail "shellcheck: ${file#"$repo"/}"
    fi
  done < <(find "$home_dir/dot_dotfiles/common" -type f ! -name '*.md' ! -name '*.zsh' -print0)
else
  printf 'note: shellcheck not installed, skipping lint\n' >&2
fi

printf '%d checks, %d failure(s)\n' "$checked" "$failures"
[ "$failures" -eq 0 ]
