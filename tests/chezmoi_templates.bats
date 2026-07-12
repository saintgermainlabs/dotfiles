#!/usr/bin/env bats

# Tests that chezmoi config templates render correctly for every host
# defined in hosts.toml, plus the unknown-host fallback and the devops
# role (used by devcontainers).

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHEZMOI="${CHEZMOI:-chezmoi}"
    source "$REPO_ROOT/tests/test_helper.bash"
}

@test "[templates] .chezmoi.toml.tmpl renders for ubuntu-laptop" {
    run bash -c "DOTFILES_HOSTNAME=ubuntu-laptop $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'role = "laptop"'
    echo "$output" | grep 'gui  = true'
    echo "$output" | grep 'encryption = "age"'
    echo "$output" | grep 'identity = "~/.config/age/key.txt"'
}

@test "[templates] .chezmoi.toml.tmpl renders for ubuntu-24 (server)" {
    run bash -c "DOTFILES_HOSTNAME=ubuntu-24 $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'role = "server"'
    echo "$output" | grep 'gui  = false'
}

@test "[templates] .chezmoi.toml.tmpl renders for vm-dev01" {
    run bash -c "DOTFILES_HOSTNAME=vm-dev01 $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'role = "vm"'
    echo "$output" | grep 'gui  = false'
}

@test "[templates] .chezmoi.toml.tmpl falls back to server/gui=false for unknown host" {
    run bash -c "DOTFILES_HOSTNAME=some-unknown-host $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'role = "server"'
    echo "$output" | grep 'gui  = false'
}

@test "[templates] .chezmoi.toml.tmpl falls back to DOTFILES_ROLE env var for unknown host" {
    run bash -c "DOTFILES_HOSTNAME=dev-container DOTFILES_ROLE=devops $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'role = "devops"'
    echo "$output" | grep 'gui  = false'
}

@test "[templates] devops role uses ephemeral age key" {
    run bash -c "DOTFILES_HOSTNAME=dev-container DOTFILES_ROLE=devops $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'identity = "/tmp/chezmoi-age-key.txt"'
    echo "$output" | grep '\[hooks.read-source-state.pre\]'
    echo "$output" | grep '\[hooks.apply.post\]'
}

@test "[templates] non-devops role uses persistent age key" {
    run bash -c "DOTFILES_HOSTNAME=ubuntu-laptop $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'identity = "~/.config/age/key.txt"'
    ! echo "$output" | grep '\[hooks'
}

@test "[templates] TOML structure: encryption before [data]" {
    run bash -c "DOTFILES_HOSTNAME=ubuntu-laptop $CHEZMOI execute-template --init < '$REPO_ROOT/home/.chezmoi.toml.tmpl'"
    [ "$status" -eq 0 ]
    # encryption must appear before [data] in valid TOML
    enc_line=$(echo "$output" | grep -n 'encryption = "age"' | cut -d: -f1)
    data_line=$(echo "$output" | grep -n '^\[data\]' | cut -d: -f1)
    [ -n "$enc_line" ]
    [ -n "$data_line" ]
    [ "$enc_line" -lt "$data_line" ]
}

@test "[templates] .chezmoiignore.tmpl renders for laptop (gui=true)" {
    run render_as_host "ubuntu-laptop" "home/.chezmoiignore.tmpl"
    [ "$status" -eq 0 ]
    # GUI paths should NOT be in the ignore list when gui=true
    ! echo "$output" | grep '\.local/bin/gui/'
    ! echo "$output" | grep 'Templates/'
}

@test "[templates] .chezmoiignore.tmpl renders for server (gui=false)" {
    run render_as_host "ubuntu-24" "home/.chezmoiignore.tmpl"
    [ "$status" -eq 0 ]
    # GUI paths SHOULD be in the ignore list when gui=false
    echo "$output" | grep '\.local/bin/gui/'
    echo "$output" | grep 'Templates/'
}

@test "[templates] .chezmoiignore.tmpl excludes other role dirs" {
    run render_as_host "ubuntu-laptop" "home/.chezmoiignore.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep '\.local/bin/server/'
    echo "$output" | grep '\.local/bin/vm/'
}
