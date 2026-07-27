#!/usr/bin/env bats

@test "rendered SSH config matches installed SSH config" {
    expected="$(mktemp)"

    # Render the template exactly as chezmoi would
    chezmoi execute-template < "$HOME/.local/share/chezmoi/dot_ssh/config.tmpl" > "$expected"

    # Compare against the installed config
    diff -u "$expected" "$HOME/.ssh/config"
}
