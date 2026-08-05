#!/bin/bash

# This function executes a command on the remote host
# Usage: remote_exec <username> <hostname> <command> [ssh_options]
remote_exec() {
    local username="$1"
    local hostname="$2"
    shift 2
    local command="$@"

    if [[ -z "$username" || -z "$hostname" || -z "$command" ]]; then
        echo "Usage: remote_exec <username> <hostname> <command> [ssh_options]"
        return 1
    fi

    ssh "$username@$hostname" "$command"
}
