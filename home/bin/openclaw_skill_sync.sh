# Sync local OpenClaw skills to the remote server.
#
# Source:
#   /home/god/dev/openclaw/skills/
#
# Destination:
#   /srv/openclaw/skills/
#
# Usage:
#   openclaw_skill_sync
#   openclaw_skill_sync --dry-run
#
openclaw_skill_sync() {
    local remote="ubuntu-server"
    local source="/home/god/dev/openclaw/skills/"
    local destination="/srv/openclaw/skills/"

    # Ensure local skills directory exists
    if [[ ! -d "$source" ]]; then
        echo "Error: local skills directory does not exist:"
        echo "  $source"
        return 1
    fi

    # Optional dry-run
    local dry_run=""
    if [[ "${1:-}" == "--dry-run" ]]; then
        dry_run="--dry-run"
        echo "DRY RUN — no files will be changed."
    fi

    echo "Syncing OpenClaw skills..."
    echo
    echo "  Local:  $source"
    echo "  Remote: $remote:$destination"
    echo

    # Make sure destination exists
    ssh "$remote" "mkdir -p '$destination'" || {
        echo "Error: could not create/access remote skills directory."
        return 1
    }

    rsync \
        -avh \
        --progress \
        $dry_run \
        "$source" \
        "$remote:$destination"

    local status=$?

    if [[ $status -eq 0 ]]; then
        echo
        echo "✓ OpenClaw skills synced successfully."
    else
        echo
        echo "✗ rsync failed with exit code $status."
    fi

    return "$status"
}