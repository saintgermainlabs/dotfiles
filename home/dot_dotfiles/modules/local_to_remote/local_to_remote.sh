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

## @internal
## @category Local-to-Remote
## @description Print an error message to stderr
## @usage _ltr_error <message>
## @arg $1 string Error message to display
## @stderr Error message with prefix
_ltr_error() {
    printf 'local_to_remote: %s\n' "$*" >&2
}

## @internal
## @category Local-to-Remote
## @description Get the configuration file path
## @usage _ltr_config_path
## @stdout Configuration file path
_ltr_config_path() {
    printf '%s\n' "${LOCAL_TO_REMOTE_CONFIG:-$HOME/.config/local_to_remote/config.sh}"
}

## @internal
## @category Local-to-Remote
## @description Load configuration from file
## @usage _ltr_load_config
## @env LOCAL_TO_REMOTE_CONFIG Path to configuration file (optional)
## @exitcode 0 If configuration is loaded successfully
## @exitcode 1 If configuration file is not found or invalid
## @stderr Error messages for missing or invalid configuration
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

## @internal
## @category Local-to-Remote
## @description Check if required commands are available
## @usage _ltr_require <command>...
## @arg $@ string Command names to check
## @exitcode 0 If all commands are available
## @exitcode 1 If any command is not found
## @stderr Error message for missing commands
_ltr_require() {
    local command_name

    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            _ltr_error "required command not found: $command_name"
            return 1
        fi
    done
}

## @internal
## @category Local-to-Remote
## @description Get the configured remote target host
## @usage _ltr_remote_target
## @requires ssh
## @stdout Remote host address
## @exitcode 0 If remote target is retrieved successfully
## @exitcode 1 If configuration loading fails
_ltr_remote_target() {
    _ltr_load_config || return
    printf '%s\n' "$LTR_REMOTE_HOST"
}

## @internal
## @category Local-to-Remote
## @description Get allowed remote path for a file key
## @usage _ltr_allowed_remote_path <key>
## @arg $1 string File key to look up
## @stdout Remote path for the file key
## @exitcode 0 If key is found
## @exitcode 1 If key is not in allowed files list
## @stderr Error message for disallowed files
_ltr_allowed_remote_path() {
    local key="$1"

    _ltr_load_config || return

    if [[ -z "${LTR_ALLOWED_FILES[$key]+x}" ]]; then
        _ltr_error "file is not in the approved configuration-file list: $key"
        return 1
    fi

    printf '%s\n' "${LTR_ALLOWED_FILES[$key]}"
}

## @internal
## @category Local-to-Remote
## @description Create a temporary file for editing
## @usage _ltr_make_temp_file <key> <remote_path>
## @arg $1 string File key
## @arg $2 string Remote path
## @stdout Path to temporary file
## @exitcode 0 If temporary file is created successfully
## @exitcode 1 If temporary file creation fails
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

## @internal
## @category Local-to-Remote
## @description Run the configured editor on a file
## @usage _ltr_run_editor <file>
## @arg $1 string File path to edit
## @env LTR_EDITOR Editor command to use (defaults to "subl -w")
## @exitcode 0 If editor runs successfully
## @exitcode 1 If editor command is not found or fails
## @stderr Error messages for editor issues
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

## @category Local-to-Remote
## @description Execute a command on the configured remote machine
## @usage remote_cmd <command> [arguments...]
## @arg $1 string Command to execute remotely
## @arg $@ string Optional arguments passed to the remote command
## @requires ssh
## @stdout Remote command stdout
## @stderr Remote command stderr
## @exitcode * Remote command exit status
## @example remote_cmd hostname
## @example remote_cmd docker ps
## @example remote_cmd ls -lah /srv
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

## @category Local-to-Remote
## @description Open an interactive shell on the configured remote machine
## @usage remote_shell
## @requires ssh
## @example remote_shell
remote_shell() {
    _ltr_load_config || return
    _ltr_require ssh || return

    ssh -t "$LTR_REMOTE_HOST"
}

## @category Local-to-Remote
## @description Upload a local file or directory to the remote machine with rsync
## @usage remote_upload <local-path> <remote-path>
## @arg $1 string Local file or directory path
## @arg $2 string Destination path on the remote machine
## @requires rsync
## @requires ssh
## @stdout rsync output
## @stderr rsync errors
## @exitcode * rsync exit status
## @example remote_upload ./compose.yaml /srv/apps/openclaw/compose.yaml
## @example remote_upload ./scripts/ /srv/scripts/
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

## @category Local-to-Remote
## @description Download a remote file or directory with rsync
## @usage remote_download <remote-path> <local-path>
## @arg $1 string File or directory path on the remote machine
## @arg $2 string Local destination path
## @requires rsync
## @requires ssh
## @stdout rsync output
## @stderr rsync errors
## @exitcode * rsync exit status
## @example remote_download /srv/apps/openclaw/compose.yaml ./compose.yaml
## @example remote_download /srv/scripts/ ./scripts/
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

## @category Local-to-Remote
## @description List configuration files approved for remote editing
## @usage remote_files
## @stdout Approved file keys and their remote paths
## @example remote_files
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

## @category Local-to-Remote
## @description Safely edit an approved remote configuration file locally
## @usage remote_edit <file-key>
## @arg $1 string Approved key shown by remote_files
## @requires rsync
## @requires ssh
## @requires sha256sum
## @stdout Status messages about the edit process
## @stderr Error messages for failures
## @exitcode 0 If file is successfully edited or unchanged
## @exitcode 1 If editing fails
## @example remote_edit openclaw-config
## @example remote_edit tailscale-serve
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

## @category Local-to-Remote
## @description Print an approved remote configuration file without editing it
## @usage remote_show <file-key>
## @arg $1 string Approved key shown by remote_files
## @requires ssh
## @stdout Remote file contents
## @stderr Error messages for failures
## @exitcode 0 If file is successfully retrieved
## @exitcode 1 If retrieval fails
## @example remote_show openclaw-config
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

## @category Local-to-Remote
## @description Create a timestamped backup of an approved remote config file
## @usage remote_backup_file <file-key>
## @arg $1 string Approved key shown by remote_files
## @requires ssh
## @stdout Path of the created remote backup
## @stderr Error messages for failures
## @exitcode 0 If backup is successfully created
## @exitcode 1 If backup creation fails
## @example remote_backup_file openclaw-config
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

## @category Local-to-Remote
## @description Execute a locally defined Bash function on the remote machine
## @usage rfunc <function> [arguments...]
## @arg $1 string Name of a local Bash function
## @arg $@ string Optional arguments passed to the function remotely
## @requires ssh
## @stdout Remote function output
## @stderr Error messages for failures
## @exitcode * Remote function exit status
## @example rfunc container_id openclaw application
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

## @category Local-to-Remote
## @description Shorthand for rfunc
## @usage r <function> [arguments...]
## @arg $1 string Name of a local Bash function
## @arg $@ string Optional arguments passed to the function remotely
## @requires ssh
## @stdout Remote function output
## @stderr Error messages for failures
## @exitcode * Remote function exit status
## @example r container_id openclaw application
r() {
    rfunc "$@"
}
