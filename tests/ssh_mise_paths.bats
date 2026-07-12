#!/usr/bin/env bats

# Tests that SSH config, mise config, and paths.toml render correctly.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHEZMOI="${CHEZMOI:-chezmoi}"
    source "$REPO_ROOT/tests/test_helper.bash"
}

# --- SSH config ---

@test "[ssh] config.tmpl renders without error" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/private_dot_ssh/config.tmpl'"
    [ "$status" -eq 0 ]
}

@test "[ssh] config.tmpl includes IdentityAgent for 1Password" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/private_dot_ssh/config.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'IdentityAgent ~/.1password/agent.sock'
}

@test "[ssh] config.tmpl includes ServerAlive settings" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/private_dot_ssh/config.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'ServerAliveInterval 60'
    echo "$output" | grep 'ServerAliveCountMax 3'
}

@test "[ssh] config.tmpl includes public servers from roles.toml" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/private_dot_ssh/config.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'github.com'
    echo "$output" | grep 'gitlab.com'
}

@test "[ssh] config.tmpl laptop role includes GitHub/GitLab/Bitbucket" {
    run render_as_host "ubuntu-laptop" "home/private_dot_ssh/config.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'Host github.com'
    echo "$output" | grep 'Host gitlab.com'
    echo "$output" | grep 'Host bitbucket.org'
}

@test "[ssh] config.tmpl server role does NOT include laptop-only hosts" {
    run render_as_host "ubuntu-24" "home/private_dot_ssh/config.tmpl"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep 'Host bitbucket.org'
}

# --- Mise config ---

@test "[mise] config.toml.tmpl renders without error" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_config/mise/config.toml.tmpl'"
    [ "$status" -eq 0 ]
}

@test "[mise] config includes common tools" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_config/mise/config.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'go = '
    echo "$output" | grep 'node = '
    echo "$output" | grep 'python = '
    echo "$output" | grep 'zoxide = '
    echo "$output" | grep 'ripgrep = '
    echo "$output" | grep 'fzf = '
}

@test "[mise] laptop config includes role-specific tools" {
    run render_as_host "ubuntu-laptop" "home/dot_config/mise/config.toml.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'terraform = '
    echo "$output" | grep 'lazydocker = '
    echo "$output" | grep 'starship = '
}

@test "[mise] server config includes role-specific tools" {
    run render_as_host "ubuntu-24" "home/dot_config/mise/config.toml.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'starship = '
    echo "$output" | grep 'lazygit = '
    ! echo "$output" | grep 'lazydocker'
}

@test "[mise] vm config includes role-specific tools" {
    run render_as_host "vm-dev01" "home/dot_config/mise/config.toml.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'lazygit = '
    ! echo "$output" | grep 'starship'
    ! echo "$output" | grep 'terraform'
}

# --- paths.toml ---

@test "[paths] paths.toml contains expected paths" {
    run grep '$HOME/.local/bin' "$REPO_ROOT/home/.chezmoidata/paths.toml"
    [ "$status" -eq 0 ]
}

@test "[paths] paths.toml contains .lmstudio/bin" {
    run grep '$HOME/.lmstudio/bin' "$REPO_ROOT/home/.chezmoidata/paths.toml"
    [ "$status" -eq 0 ]
}

@test "[paths] paths.toml contains .opencode/bin" {
    run grep '$HOME/.opencode/bin' "$REPO_ROOT/home/.chezmoidata/paths.toml"
    [ "$status" -eq 0 ]
}

@test "[paths] setup-path.tmpl file exists and exports PATH" {
    [ -f "$REPO_ROOT/home/.chezmoitemplates/setup-path.tmpl" ]
    run grep 'export PATH' "$REPO_ROOT/home/.chezmoitemplates/setup-path.tmpl"
    [ "$status" -eq 0 ]
}
