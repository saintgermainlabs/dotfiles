#!/usr/bin/env bats

# Tests that core source files exist and are well-formed.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "[common] key chezmoi data files exist" {
    [ -f "$REPO_ROOT/home/.chezmoidata/hosts.toml" ]
    [ -f "$REPO_ROOT/home/.chezmoidata/roles.toml" ]
    [ -f "$REPO_ROOT/home/.chezmoidata/fragments.toml" ]
    [ -f "$REPO_ROOT/home/.chezmoidata/paths.toml" ]
}

@test "[common] key chezmoi templates exist" {
    [ -f "$REPO_ROOT/home/.chezmoi.toml.tmpl" ]
    [ -f "$REPO_ROOT/home/.chezmoiignore.tmpl" ]
    [ -f "$REPO_ROOT/home/.chezmoitemplates/load-fragments.tmpl" ]
    [ -f "$REPO_ROOT/home/.chezmoitemplates/setup-path.tmpl" ]
}

@test "[common] shell config templates exist" {
    [ -f "$REPO_ROOT/home/dot_bashrc.tmpl" ]
    [ -f "$REPO_ROOT/home/dot_zshrc.tmpl" ]
}

@test "[common] dotfiles modules exist" {
    [ -f "$REPO_ROOT/home/dot_dotfiles/common/aliases" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/common/functions" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/common/prompt" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/bash/init" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/bash/late-init" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/zsh/init" ]
    [ -f "$REPO_ROOT/home/dot_dotfiles/zsh/late-init" ]
}

@test "[common] .chezmoiroot points to home/" {
    run cat "$REPO_ROOT/.chezmoiroot"
    [ "$status" -eq 0 ]
    [ "$output" = "home" ]
}

@test "[common] .chezmoiversion exists" {
    [ -f "$REPO_ROOT/.chezmoiversion" ]
}

@test "[common] hosts.toml defines expected hosts" {
    run grep 'ubuntu-laptop' "$REPO_ROOT/home/.chezmoidata/hosts.toml"
    [ "$status" -eq 0 ]
    run grep 'ubuntu-24' "$REPO_ROOT/home/.chezmoidata/hosts.toml"
    [ "$status" -eq 0 ]
    run grep 'vm-dev01' "$REPO_ROOT/home/.chezmoidata/hosts.toml"
    [ "$status" -eq 0 ]
}

@test "[common] roles.toml has common tools" {
    run grep 'go' "$REPO_ROOT/home/.chezmoidata/roles.toml"
    [ "$status" -eq 0 ]
    run grep 'node' "$REPO_ROOT/home/.chezmoidata/roles.toml"
    [ "$status" -eq 0 ]
    run grep 'python' "$REPO_ROOT/home/.chezmoidata/roles.toml"
    [ "$status" -eq 0 ]
}

@test "[common] roles.toml has gui packages section" {
    run grep '\[packages.gui\]' "$REPO_ROOT/home/.chezmoidata/roles.toml"
    [ "$status" -eq 0 ]
}

@test "[common] no desktop path/role references remain in templates" {
    # "desktop" as a word in comments/echo (e.g. "1Password desktop app") is fine,
    # but desktop as a path or role must not exist.
    run bash -c "grep -rn 'dot_local/bin/desktop\|\.role.*desktop\|role.*=.*\"desktop\"\|bin/desktop/' '$REPO_ROOT/home/' --include='*.tmpl' --include='*.sh' || true"
    [ -z "$output" ]
}
