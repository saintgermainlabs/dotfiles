#!/usr/bin/env bash
# Shared helper for bats tests.
# Provides a function to generate a per-host chezmoi config so that
# non-init template renders (which read from the existing config) can
# be tested as if running on a different host.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI="${CHEZMOI:-chezmoi}"
TMPDIR_TESTS="${TMPDIR:-/tmp}"

# Generate a chezmoi config TOML for the given hostname and print its path.
# Usage: config_path=$(render_host_config "ubuntu-24")
render_host_config() {
    local hostname="$1"
    local cfg="$TMPDIR_TESTS/chezmoi-test-config-${hostname}.toml"
    DOTFILES_HOSTNAME="$hostname" $CHEZMOI execute-template --init \
        < "$REPO_ROOT/home/.chezmoi.toml.tmpl" > "$cfg" 2>&1
    echo "$cfg"
}

# Render a template as if on a specific host.
# Usage: render_as_host "ubuntu-24" "home/.chezmoiignore.tmpl"
render_as_host() {
    local hostname="$1"
    local template="$2"
    local cfg
    cfg=$(render_host_config "$hostname")
    $CHEZMOI execute-template --config "$cfg" < "$REPO_ROOT/$template"
}