#!/usr/bin/env bash
# Verify expected primordial devcontainer bind mounts and volumes.
set -euo pipefail

OUT_DIR="${PRIMORDIAL_STATE_DIR:-/var/lib/primordial}"
OUT_FILE="${OUT_DIR}/mounts.json"
SSH_DIR="${HOME}/.ssh"

log() { printf '[verify-mounts] %s\n' "$*"; }
warn() { printf '[verify-mounts] WARN: %s\n' "$*" >&2; }

mkdir -p "${OUT_DIR}"

mount_source() {
  local target="$1"
  findmnt -n -o SOURCE --target "${target}" 2>/dev/null || echo ""
}

ssh_key_count=0
if [ -d "${SSH_DIR}" ] && [ -r "${SSH_DIR}" ]; then
  ssh_key_count="$(find "${SSH_DIR}" -maxdepth 1 -type f \( -name 'id_*' -o -name '*.pub' \) 2>/dev/null | wc -l | tr -d ' ')"
fi

python3 - "${OUT_FILE}" "${SSH_DIR}" "${ssh_key_count}" <<'PY'
import json
import os
import subprocess
import sys

out_file, ssh_dir, ssh_key_count = sys.argv[1:4]
ssh_key_count = int(ssh_key_count)

def mount_info(path):
    try:
        output = subprocess.check_output(
            ["findmnt", "-n", "-o", "SOURCE,FSTYPE,OPTIONS", "--target", path],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except subprocess.CalledProcessError:
        return {"present": os.path.exists(path), "source": "", "fstype": "", "options": ""}
    parts = output.split()
    source = parts[0] if parts else ""
    fstype = parts[1] if len(parts) > 1 else ""
    options = parts[2] if len(parts) > 2 else ""
    return {
        "present": os.path.exists(path),
        "source": source,
        "fstype": fstype,
        "options": options,
        "is_mount_point": bool(source),
    }

checks = {
    "ssh_dir": {
        **mount_info(ssh_dir),
        "path": ssh_dir,
        "expected": "bind mount from host ~/.ssh (readonly)",
        "key_file_count": ssh_key_count,
    },
    "primordial_state": {
        **mount_info("/var/lib/primordial"),
        "path": "/var/lib/primordial",
        "expected": "named volume devcontainer-primordial-state",
    },
    "tailscale_state": {
        **mount_info("/var/lib/tailscale"),
        "path": "/var/lib/tailscale",
        "expected": "named volume devcontainer-tailscale-state*",
    },
}

data = {"checks": checks}

with open(out_file, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY

if [ ! -d "${SSH_DIR}" ]; then
  warn "~/.ssh is missing — ensure host ~/.ssh is bind-mounted"
elif [ ! -r "${SSH_DIR}" ]; then
  warn "~/.ssh is not readable"
elif [ "${ssh_key_count}" -eq 0 ]; then
  warn "~/.ssh is mounted but no key files were found"
else
  log "OK: ~/.ssh mounted with ${ssh_key_count} key file(s)"
fi

if [ -n "${OP_USE_APP_INTEGRATION:-}" ] && [ "${OP_USE_APP_INTEGRATION}" != "0" ]; then
  if [ -S "${HOME}/.1password/agent.sock" ] || [ -L "${HOME}/.1password/agent.sock" ]; then
    log "OK: 1Password agent socket mounted at ~/.1password/agent.sock"
  else
    warn "~/.1password/agent.sock not found — enable app integration on the host and rebuild"
  fi
fi

if mount_source /var/lib/primordial | grep -q 'devcontainer-primordial-state\|/$'; then
  log "OK: /var/lib/primordial state directory ready"
else
  log "OK: /var/lib/primordial present"
fi

if [ -d /var/lib/tailscale ]; then
  log "OK: /var/lib/tailscale present"
else
  warn "/var/lib/tailscale missing — Tailscale volume may not be configured for this profile"
fi

log "Mount report written to ${OUT_FILE}"
