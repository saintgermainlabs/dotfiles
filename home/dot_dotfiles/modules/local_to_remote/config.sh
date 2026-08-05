#!/usr/bin/env bash
# local_to_remote configuration
#
# Recommended location:
#   ~/.config/local_to_remote/config.sh
#
# If managed by chezmoi, this can instead be generated from a template.

# SSH host alias from ~/.ssh/config.
LTR_REMOTE_HOST="ubuntu"

# Editor command.
#
# `-w` is important for Sublime Text because remote_edit needs to wait until
# the editor window/file is closed before uploading the result.
LTR_EDITOR="subl -w"

# -----------------------------------------------------------------------------
# Approved remote configuration files
# -----------------------------------------------------------------------------
#
# remote_edit REFUSES to edit arbitrary paths. Only entries in this associative
# array are permitted.
#
# Usage:
#   remote_files
#   remote_edit openclaw-config
#
declare -A LTR_ALLOWED_FILES=(
    # OpenClaw
    ["openclaw-config"]="/data/.openclaw/openclaw.json"

    # Example Tailscale Serve config:
    # ["openclaw-tailscale"]="/srv/apps/openclaw/tailscale/serve.json"

    # Example Coolify-related compose:
    # ["openclaw-compose"]="/srv/apps/openclaw/compose.yaml"

    # Add additional approved files here:
    # ["n8n-compose"]="/srv/apps/n8n/compose.yaml"
)
