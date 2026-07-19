#!/usr/bin/env bats

# Tests that shell config templates (bashrc, zshrc) render correctly,
# have valid syntax, and that zoxide is initialized at the very end.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHEZMOI="${CHEZMOI:-chezmoi}"
    source "$REPO_ROOT/tests/test_helper.bash"
}

render_shell_template() {
    local template="$1"
    local cfg
    cfg=$(render_host_config "ubuntu-laptop")
    $CHEZMOI execute-template --config "$cfg" --source "$REPO_ROOT/home" < "$REPO_ROOT/home/$template"
}

@test "[shell] bashrc template renders without error" {
    run render_shell_template "dot_bashrc.tmpl"
    [ "$status" -eq 0 ]
}

@test "[shell] zshrc template renders without error" {
    run render_shell_template "dot_zshrc.tmpl"
    [ "$status" -eq 0 ]
}

@test "[shell] bashrc has valid bash syntax" {
    run bash -n <(render_shell_template "dot_bashrc.tmpl")
    [ "$status" -eq 0 ]
}

@test "[shell] zshrc has valid zsh syntax" {
    run zsh -n <(render_shell_template "dot_zshrc.tmpl")
    [ "$status" -eq 0 ]
}

@test "[shell] bashrc sources compiled shell" {
    run render_shell_template "dot_bashrc.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'compiled/shell'
}

@test "[shell] zshrc sources compiled shell" {
    run render_shell_template "dot_zshrc.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'compiled/shell'
}

@test "[shell] bashrc sources late-init at the very end" {
    run render_shell_template "dot_bashrc.tmpl"
    [ "$status" -eq 0 ]
    last_line=$(echo "$output" | grep -v '^$' | tail -1)
    echo "$last_line" | grep 'bash/late-init'
}

@test "[shell] zshrc sources late-init at the very end" {
    run render_shell_template "dot_zshrc.tmpl"
    [ "$status" -eq 0 ]
    last_line=$(echo "$output" | grep -v '^$' | tail -1)
    echo "$last_line" | grep 'zsh/late-init'
}

@test "[shell] bashrc uses setup-path.tmpl (not hardcoded PATH)" {
    run render_shell_template "dot_bashrc.tmpl"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'export PATH='
    echo "$output" | grep '\$HOME/bin'
    echo "$output" | grep '\$HOME/.local/bin'
}

@test "[shell] bashrc and zshrc produce identical PATH exports" {
    bash_path=$(render_shell_template "dot_bashrc.tmpl" | grep 'export PATH=')
    zsh_path=$(render_shell_template "dot_zshrc.tmpl" | grep 'export PATH=')
    [ "$bash_path" = "$zsh_path" ]
}

@test "[shell] compiled shell includes common aliases and docker fragment" {
    run bash -c "source '$REPO_ROOT/tests/test_helper.bash'; cfg=\$(render_host_config ubuntu-laptop); $CHEZMOI execute-template --config \"\$cfg\" --source '$REPO_ROOT/home' < '$REPO_ROOT/home/dot_dotfiles/compiled/shell.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F '# ── common/aliases ──'
    echo "$output" | grep -F '# ── fragments/docker_functions ──'
    echo "$output" | grep -F 'alias l='
    echo "$output" | grep -F 'cps()'
    echo "$output" | grep -F 'manual()'
}

@test "[shell] help_functions defines manual and aliases" {
    run bash -n "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
    [ "$status" -eq 0 ]
    grep -q '^manual()' "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
    grep -q '^aliases()' "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
}

@test "[shell] manual() reads compiled shell with section markers" {
    local tmp_home cfg compiled
    tmp_home="$(mktemp -d)"
    cfg=$(render_host_config "ubuntu-laptop")
    compiled=$($CHEZMOI execute-template --config "$cfg" --source "$REPO_ROOT/home" \
        < "$REPO_ROOT/home/dot_dotfiles/compiled/shell.tmpl")
    mkdir -p "$tmp_home/.dotfiles/compiled"
    printf '%s\n' "$compiled" > "$tmp_home/.dotfiles/compiled/shell"

    run bash -c "export HOME='$tmp_home'; source '$REPO_ROOT/home/dot_dotfiles/fragments/help_functions'; manual cps"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F 'fragments/docker_functions'
    echo "$output" | grep -F 'List running containers'
    rm -rf "$tmp_home"
}

@test "[shell] aliases() reads compiled shell" {
    local tmp_home cfg compiled
    tmp_home="$(mktemp -d)"
    cfg=$(render_host_config "ubuntu-laptop")
    compiled=$($CHEZMOI execute-template --config "$cfg" --source "$REPO_ROOT/home" \
        < "$REPO_ROOT/home/dot_dotfiles/compiled/shell.tmpl")
    mkdir -p "$tmp_home/.dotfiles/compiled"
    printf '%s\n' "$compiled" > "$tmp_home/.dotfiles/compiled/shell"

    run bash -c "export HOME='$tmp_home'; source '$REPO_ROOT/home/dot_dotfiles/fragments/help_functions'; aliases ll"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F 'common/aliases'
    echo "$output" | grep -F 'Long listing with git status'
    rm -rf "$tmp_home"
}

@test "[shell] verbose mode logs compiled sections to stderr" {
    local tmp_home cfg compiled settings
    tmp_home="$(mktemp -d)"
    cfg=$(render_host_config "ubuntu-laptop")
    compiled=$($CHEZMOI execute-template --config "$cfg" --source "$REPO_ROOT/home" \
        < "$REPO_ROOT/home/dot_dotfiles/compiled/shell.tmpl")
    mkdir -p "$tmp_home/.dotfiles/compiled" "$tmp_home/.config/dotfiles"
    printf '%s\n' "$compiled" > "$tmp_home/.dotfiles/compiled/shell"
    printf 'VERBOSE: 1\n' > "$tmp_home/.config/dotfiles/settings.yaml"

    run bash -c "export HOME='$tmp_home' DOTFILES_BOOTSTRAP=bashrc; source '$tmp_home/.dotfiles/compiled/shell' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F 'bootstrapped from bashrc'
    echo "$output" | grep -F 'common/aliases'
    echo "$output" | grep -F 'fragments/docker_functions'
    echo "$output" | grep -F 'compiled/shell ready'
    rm -rf "$tmp_home"
}

@test "[shell] verbose mode is silent when VERBOSE is 0" {
    local tmp_home cfg compiled
    tmp_home="$(mktemp -d)"
    cfg=$(render_host_config "ubuntu-laptop")
    compiled=$($CHEZMOI execute-template --config "$cfg" --source "$REPO_ROOT/home" \
        < "$REPO_ROOT/home/dot_dotfiles/compiled/shell.tmpl")
    mkdir -p "$tmp_home/.dotfiles/compiled" "$tmp_home/.config/dotfiles"
    printf '%s\n' "$compiled" > "$tmp_home/.dotfiles/compiled/shell"
    printf 'VERBOSE: 0\n' > "$tmp_home/.config/dotfiles/settings.yaml"

    run bash -c "export HOME='$tmp_home' DOTFILES_BOOTSTRAP=bashrc; source '$tmp_home/.dotfiles/compiled/shell' 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    rm -rf "$tmp_home"
}
