#!/usr/bin/env bats

# Tests that shell config templates (bashrc, zshrc) render correctly,
# have valid syntax, and that zoxide is initialized at the very end.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHEZMOI="${CHEZMOI:-chezmoi}"
    source "$REPO_ROOT/tests/test_helper.bash"
}

@test "[shell] bashrc template renders without error" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'"
    [ "$status" -eq 0 ]
}

@test "[shell] zshrc template renders without error" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'"
    [ "$status" -eq 0 ]
}

@test "[shell] bashrc has valid bash syntax" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl' | bash -n"
    [ "$status" -eq 0 ]
}

@test "[shell] zshrc has valid zsh syntax" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl' | zsh -n"
    [ "$status" -eq 0 ]
}

@test "[shell] bashrc sources late-init at the very end" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'"
    [ "$status" -eq 0 ]
    # The last non-empty line should source bash/late-init
    last_line=$(echo "$output" | grep -v '^$' | tail -1)
    echo "$last_line" | grep 'bash/late-init'
}

@test "[shell] zshrc sources late-init at the very end" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'"
    [ "$status" -eq 0 ]
    last_line=$(echo "$output" | grep -v '^$' | tail -1)
    echo "$last_line" | grep 'zsh/late-init'
}

@test "[shell] bashrc uses setup-path.tmpl (not hardcoded PATH)" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'export PATH='
    # Should contain paths from paths.toml, not just .local/bin
    echo "$output" | grep '\$HOME/bin'
    echo "$output" | grep '\$HOME/.local/bin'
    echo "$output" | grep '\$HOME/.opencode/bin'
    echo "$output" | grep '\$HOME/.lmstudio/bin'
}

@test "[shell] zshrc uses setup-path.tmpl (not hardcoded PATH)" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'export PATH='
    echo "$output" | grep '\$HOME/bin'
    echo "$output" | grep '\$HOME/.local/bin'
    echo "$output" | grep '\$HOME/.opencode/bin'
    echo "$output" | grep '\$HOME/.lmstudio/bin'
}

@test "[shell] bashrc and zshrc produce identical PATH exports" {
    bash_path=$(bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'" | grep 'export PATH=')
    zsh_path=$(bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'" | grep 'export PATH=')
    [ "$bash_path" = "$zsh_path" ]
}

@test "[shell] bashrc loads fragments via load-fragments.tmpl" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'"
    [ "$status" -eq 0 ]
    # load-fragments.tmpl emits [ -r "${DF_DIR}/fragments/<name>" ] && . ...
    echo "$output" | grep 'fragments/'
}

@test "[shell] zshrc loads fragments via load-fragments.tmpl" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'fragments/'
}

@test "[shell] bashrc sources bootstrap modules" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_bashrc.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'common/aliases'
    echo "$output" | grep 'common/functions'
    echo "$output" | grep 'bash/init'
}

@test "[shell] zshrc sources bootstrap modules" {
    run bash -c "$CHEZMOI execute-template < '$REPO_ROOT/home/dot_zshrc.tmpl'"
    [ "$status" -eq 0 ]
    echo "$output" | grep 'common/aliases'
    echo "$output" | grep 'common/functions'
    echo "$output" | grep 'zsh/init'
}

@test "[shell] bashrc sources help_functions after role-aliases" {
    grep -q 'role-aliases' "$REPO_ROOT/home/dot_bashrc.tmpl"
    grep -q 'fragments/help_functions' "$REPO_ROOT/home/dot_bashrc.tmpl"
    # help_functions must be sourced after role-aliases
    awk '/role-aliases/{ra=NR} /help_functions/{hf=NR} END{exit !(ra && hf && hf>ra)}' \
        "$REPO_ROOT/home/dot_bashrc.tmpl"
}

@test "[shell] zshrc sources help_functions after role-aliases" {
    grep -q 'role-aliases' "$REPO_ROOT/home/dot_zshrc.tmpl"
    grep -q 'fragments/help_functions' "$REPO_ROOT/home/dot_zshrc.tmpl"
    awk '/role-aliases/{ra=NR} /help_functions/{hf=NR} END{exit !(ra && hf && hf>ra)}' \
        "$REPO_ROOT/home/dot_zshrc.tmpl"
}

@test "[shell] help_functions defines manual and aliases" {
    run bash -n "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
    [ "$status" -eq 0 ]
    grep -q '^manual()' "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
    grep -q '^aliases()' "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions"
}

@test "[shell] manual() shows comment descriptions for functions" {
    local tmp_home
    tmp_home="$(mktemp -d)"
    mkdir -p "$tmp_home/.dotfiles/fragments" "$tmp_home/.config/dotfiles"
    cp -r "$REPO_ROOT/home/dot_dotfiles/common" "$tmp_home/.dotfiles/"
    cp "$REPO_ROOT/home/dot_dotfiles/fragments/docker_functions" "$tmp_home/.dotfiles/fragments/"
    cp "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions" "$tmp_home/.dotfiles/fragments/"
    echo '# test' > "$tmp_home/.config/dotfiles/role-aliases"

    run bash -c "export HOME='$tmp_home'; source '$tmp_home/.dotfiles/fragments/help_functions'; manual cps"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F 'List running containers'
    rm -rf "$tmp_home"
}

@test "[shell] aliases() shows comment descriptions" {
    local tmp_home
    tmp_home="$(mktemp -d)"
    mkdir -p "$tmp_home/.dotfiles/fragments" "$tmp_home/.config/dotfiles"
    cp -r "$REPO_ROOT/home/dot_dotfiles/common" "$tmp_home/.dotfiles/"
    cp "$REPO_ROOT/home/dot_dotfiles/fragments/help_functions" "$tmp_home/.dotfiles/fragments/"
    echo '# test' > "$tmp_home/.config/dotfiles/role-aliases"

    run bash -c "export HOME='$tmp_home'; source '$tmp_home/.dotfiles/fragments/help_functions'; aliases ll"
    [ "$status" -eq 0 ]
    echo "$output" | grep -F 'Long listing with git status'
    rm -rf "$tmp_home"
}