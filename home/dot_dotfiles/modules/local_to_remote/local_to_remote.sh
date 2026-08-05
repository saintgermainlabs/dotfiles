#!/usr/bin/env bash
# local_to_remote.sh
#
# Local-to-remote helper functions for dotfiles.
#
# Intended to be sourced from your shell configuration:
#
#   source "$HOME/.config/dotfiles/modules/local_to_remote/local_to_remote.sh"
#
# Configuration is loaded from:
#
#   ${LOCAL_TO_REMOTE_CONFIG:-$HOME/.config/local_to_remote/config.sh}
#
# The config file should define:
#   LTR_REMOTE_HOST
#   LTR_EDITOR
#   LTR_ALLOWED_FILES
#
# Requirements:
#   bash, ssh, rsync
#
# Optional:
#   subl / sublime_text / another editor command configured via LTR_EDITOR

# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

_ltr_error() {
    printf 'local_to_remote: %s\n' "$*" >&2
}

_ltr_config_path() {
    printf '%s\n' "${LOCAL_TO_REMOTE_CONFIG:-$HOME/.config/local_to_remote/config.sh}"
}

_ltr_load_config() {
    local config
    config="$(_ltr_config_path)"

    if [[ ! -f "$config" ]]; then
        _ltr_error "configuration file not found: $config"
        _ltr_error "copy config.example.sh to that location and edit it."
        return 1
    fi

    # shellcheck source=/dev/null
    source "$config"

    : "${LTR_REMOTE_HOST:?LTR_REMOTE_HOST is not configured}"
    : "${LTR_EDITOR:=subl -w}"

    if ! declare -p LTR_ALLOWED_FILES >/dev/null 2>&1; then
        declare -gA LTR_ALLOWED_FILES=()
    fi
}

_ltr_require() {
    local command_name

    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            _ltr_error "required command not found: $command_name"
            return 1
        fi
    done
}

_ltr_remote_target() {
    _ltr_load_config || return
    printf '%s\n' "$LTR_REMOTE_HOST"
}

_ltr_allowed_remote_path() {
    local key="$1"

    _ltr_load_config || return

    if [[ -z "${LTR_ALLOWED_FILES[$key]+x}" ]]; then
        _ltr_error "file is not in the approved configuration-file list: $key"
        return 1
    fi

    printf '%s\n' "${LTR_ALLOWED_FILES[$key]}"
}

_ltr_make_temp_file() {
    local key="$1"
    local remote_path="$2"
    local suffix=""
    local filename

    filename="${remote_path##*/}"

    if [[ "$filename" == *.* ]]; then
        suffix=".${filename##*.}"
    fi

    mktemp "${TMPDIR:-/tmp}/ltr-${key//[^a-zA-Z0-9_-]/_}.XXXXXX${suffix}"
}

_ltr_run_editor() {
    local file="$1"
    local -a editor_cmd

    _ltr_load_config || return

    # Deliberately allow an editor command with arguments, e.g.:
    #   LTR_EDITOR="subl -w"
    #
    # shellcheck disable=SC2206
    editor_cmd=($LTR_EDITOR)

    if [[ ${#editor_cmd[@]} -eq 0 ]]; then
        _ltr_error "LTR_EDITOR is empty"
        return 1
    fi

    if ! command -v "${editor_cmd[0]}" >/dev/null 2>&1; then
        _ltr_error "editor command not found: ${editor_cmd[0]}"
        return 1
    fi

    "${editor_cmd[@]}" "$file"
}

# -----------------------------------------------------------------------------
# Public functions
# -----------------------------------------------------------------------------

# @name        remote_cmd
# @category    local_to_remote
# @summary     Execute a command on the configured remote machine.
# @usage       remote_cmd <command> [arguments...]
# @arg         command      Command to execute remotely.
# @arg         arguments    Arguments passed to the remote command.
# @returns     Remote command stdout, stderr, and exit status.
# @requires    ssh
# @example     remote_cmd hostname
# @example     remote_cmd docker ps
# @example     remote_cmd ls -lah /srv
# @description
#   Executes the supplied command on LTR_REMOTE_HOST over SSH.
#   Arguments are shell-escaped locally before being sent to the remote Bash
#   shell, so normal arguments containing spaces are preserved.
remote_cmd() {
    _ltr_load_config || return
    _ltr_require ssh || return

    if [[ $# -eq 0 ]]; then
        _ltr_error "usage: remote_cmd <command> [arguments...]"
        return 1
    fi

    local remote_command=""
    local arg

    for arg in "$@"; do
        printf -v arg '%q' "$arg"
        remote_command+="${remote_command:+ }${arg}"
    done

    ssh "$LTR_REMOTE_HOST" "bash -lc $(printf '%q' "$remote_command")"
}

# @name        remote_shell
# @category    local_to_remote
# @summary     Open an interactive shell on the configured remote machine.
# @usage       remote_shell
# @returns     Interactive SSH session.
# @requires    ssh
# @example     remote_shell
remote_shell() {
    _ltr_load_config || return
    _ltr_require ssh || return

    ssh -t "$LTR_REMOTE_HOST"
}

# @name        remote_upload
# @category    local_to_remote
# @summary     Upload a local file or directory to the remote machine with rsync.
# @usage       remote_upload <local-path> <remote-path>
# @arg         local-path   Local file or directory.
# @arg         remote-path  Destination path on the remote machine.
# @returns     rsync output and exit status.
# @requires    rsync ssh
# @example     remote_upload ./compose.yaml /srv/apps/openclaw/compose.yaml
# @example     remote_upload ./scripts/ /srv/scripts/
# @description
#   Uses rsync over SSH. Directory trailing-slash semantics are preserved.
remote_upload() {
    _ltr_load_config || return
    _ltr_require rsync ssh || return

    if [[ $# -ne 2 ]]; then
        _ltr_error "usage: remote_upload <local-path> <remote-path>"
        return 1
    fi

    local local_path="$1"
    local remote_path="$2"

    if [[ ! -e "$local_path" ]]; then
        _ltr_error "local path does not exist: $local_path"
        return 1
    fi

    rsync -a --human-readable --progress \
        -e ssh \
        -- "$local_path" "${LTR_REMOTE_HOST}:${remote_path}"
}

# @name        remote_download
# @category    local_to_remote
# @summary     Download a remote file or directory with rsync.
# @usage       remote_download <remote-path> <local-path>
# @arg         remote-path  File or directory on the remote machine.
# @arg         local-path   Local destination path.
# @returns     rsync output and exit status.
# @requires    rsync ssh
# @example     remote_download /srv/apps/openclaw/compose.yaml ./compose.yaml
# @example     remote_download /srv/scripts/ ./scripts/
remote_download() {
    _ltr_load_config || return
    _ltr_require rsync ssh || return

    if [[ $# -ne 2 ]]; then
        _ltr_error "usage: remote_download <remote-path> <local-path>"
        return 1
    fi

    local remote_path="$1"
    local local_path="$2"

    rsync -a --human-readable --progress \
        -e ssh \
        -- "${LTR_REMOTE_HOST}:${remote_path}" "$local_path"
}

# @name        remote_files
# @category    local_to_remote
# @summary     List configuration files approved for remote editing.
# @usage       remote_files
# @returns     Approved file keys and their remote paths.
# @example     remote_files
# @description
#   Displays only files explicitly configured in LTR_ALLOWED_FILES.
remote_files() {
    _ltr_load_config || return

    if [[ ${#LTR_ALLOWED_FILES[@]} -eq 0 ]]; then
        printf 'No approved files configured.\n'
        return 0
    fi

    local key
    while IFS= read -r key; do
        printf '%-24s %s\n' "$key" "${LTR_ALLOWED_FILES[$key]}"
    done < <(printf '%s\n' "${!LTR_ALLOWED_FILES[@]}" | sort)
}

# @name        remote_edit
# @category    local_to_remote
# @summary     Safely edit an approved remote configuration file locally.
# @usage       remote_edit <file-key>
# @arg         file-key     Approved key shown by remote_files.
# @returns     Downloads, edits, validates change state, and reuploads the file.
# @requires    rsync ssh
# @example     remote_edit openclaw-config
# @example     remote_edit tailscale-serve
# @description
#   Only paths listed in LTR_ALLOWED_FILES may be edited.
#
#   Workflow:
#     1. Verify the remote file exists.
#     2. Download it to a temporary local file.
#     3. Open it with LTR_EDITOR.
#     4. If unchanged, do nothing.
#     5. If changed, create a timestamped remote backup.
#     6. Upload the edited copy back to the same path.
#
#   The temporary local file is removed when the function exits.
remote_edit() {
    _ltr_load_config || return
    _ltr_require rsync ssh sha256sum || return

    if [[ $# -ne 1 ]]; then
        _ltr_error "usage: remote_edit <file-key>"
        _ltr_error "run 'remote_files' to see approved files."
        return 1
    fi

    local key="$1"
    local remote_path
    local temp_file
    local before_hash
    local after_hash
    local timestamp

    remote_path="$(_ltr_allowed_remote_path "$key")" || return

    if ! ssh "$LTR_REMOTE_HOST" test -f "$remote_path"; then
        _ltr_error "remote file does not exist: $remote_path"
        return 1
    fi

    temp_file="$(_ltr_make_temp_file "$key" "$remote_path")" || return
    trap 'rm -f "$temp_file"' RETURN

    rsync -a -e ssh -- "${LTR_REMOTE_HOST}:${remote_path}" "$temp_file" || return

    before_hash="$(sha256sum "$temp_file" | awk '{print $1}')"

    _ltr_run_editor "$temp_file" || return

    after_hash="$(sha256sum "$temp_file" | awk '{print $1}')"

    if [[ "$before_hash" == "$after_hash" ]]; then
        printf 'No changes made to %s.\n' "$key"
        return 0
    fi

    timestamp="$(date +%Y%m%d-%H%M%S)"

    printf 'Creating remote backup:\n  %s.%s.bak\n' "$remote_path" "$timestamp"

    ssh "$LTR_REMOTE_HOST" \
        "cp -- $(printf '%q' "$remote_path") $(printf '%q' "${remote_path}.${timestamp}.bak")" \
        || return

    rsync -a -e ssh -- "$temp_file" "${LTR_REMOTE_HOST}:${remote_path}" || return

    printf 'Updated remote file:\n  %s\n' "$remote_path"
}

# @name        remote_show
# @category    local_to_remote
# @summary     Print an approved remote configuration file without editing it.
# @usage       remote_show <file-key>
# @arg         file-key     Approved key shown by remote_files.
# @returns     Remote file contents.
# @requires    ssh
# @example     remote_show openclaw-config
remote_show() {
    _ltr_load_config || return
    _ltr_require ssh || return

    if [[ $# -ne 1 ]]; then
        _ltr_error "usage: remote_show <file-key>"
        return 1
    fi

    local remote_path
    remote_path="$(_ltr_allowed_remote_path "$1")" || return

    ssh "$LTR_REMOTE_HOST" cat -- "$remote_path"
}

# @name        remote_backup_file
# @category    local_to_remote
# @summary     Create a timestamped backup of an approved remote config file.
# @usage       remote_backup_file <file-key>
# @arg         file-key     Approved key shown by remote_files.
# @returns     Path of the created remote backup.
# @requires    ssh
# @example     remote_backup_file openclaw-config
remote_backup_file() {
    _ltr_load_config || return
    _ltr_require ssh || return

    if [[ $# -ne 1 ]]; then
        _ltr_error "usage: remote_backup_file <file-key>"
        return 1
    fi

    local remote_path
    local timestamp
    local backup_path

    remote_path="$(_ltr_allowed_remote_path "$1")" || return
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_path="${remote_path}.${timestamp}.bak"

    ssh "$LTR_REMOTE_HOST" \
        "cp -- $(printf '%q' "$remote_path") $(printf '%q' "$backup_path")" \
        || return

    printf '%s\n' "$backup_path"
}

# @name        rfunc
# @category    local_to_remote
# @summary     Execute a locally defined Bash function on the remote machine.
# @usage       rfunc <function> [arguments...]
# @arg         function     Name of a local Bash function.
# @arg         arguments    Arguments passed to the function remotely.
# @returns     Remote function output and exit status.
# @requires    ssh bash
# @example     rfunc container_id openclaw application
# @description
#   Sends the definition of one local Bash function over SSH and executes it
#   on the configured remote machine.
#
#   This works best for self-contained functions. Dependencies on additional
#   local functions are not automatically transferred.
rfunc() {
    _ltr_load_config || return
    _ltr_require ssh || return

    if [[ $# -lt 1 ]]; then
        _ltr_error "usage: rfunc <function> [arguments...]"
        return 1
    fi

    local function_name="$1"
    shift

    if ! declare -F "$function_name" >/dev/null; then
        _ltr_error "local function not found: $function_name"
        return 1
    fi

    {
        declare -f "$function_name"
        printf '\n%s' "$function_name"

        local arg
        for arg in "$@"; do
            printf ' %q' "$arg"
        done

        printf '\n'
    } | ssh "$LTR_REMOTE_HOST" 'bash -s'
}

# @name        r
# @category    local_to_remote
# @summary     Shorthand for rfunc.
# @usage       r <function> [arguments...]
# @example     r container_id openclaw application
r() {
    rfunc "$@"
}
