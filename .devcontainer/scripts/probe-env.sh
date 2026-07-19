#!/usr/bin/env bash
# Collect non-secret environment facts for Linux-management devcontainers.
set -euo pipefail

MODE="${1:-runtime}"
OUT_DIR="${PRIMORDIAL_STATE_DIR:-/var/lib/primordial}"
OUT_FILE="${OUT_DIR}/env.json"
BUILD_FILE="${OUT_DIR}/image-env.json"

mkdir -p "${OUT_DIR}"

write_probe() {
  local label="$1"
  local dest="$2"

  python3 - "${label}" "${dest}" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

label, dest = sys.argv[1:3]

def run(cmd, default=""):
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError:
        return default

def bool_cmd(cmd):
    try:
        subprocess.check_call(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

os_release = {}
try:
    with open("/etc/os-release") as fh:
        for line in fh:
            if "=" in line:
                key, value = line.strip().split("=", 1)
                os_release[key] = value.strip('"')
except OSError:
    pass

data = {
    "captured_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "capture_mode": label,
    "hostname": run("hostname", "unknown"),
    "kernel": run("uname -sr", "unknown"),
    "architecture": run("uname -m", "unknown"),
    "dpkg_arch": run("dpkg --print-architecture", "unknown"),
    "ubuntu_version": f"{os_release.get('NAME', 'Ubuntu')} {os_release.get('VERSION_ID', 'unknown')}",
    "container": os.path.exists("/.dockerenv"),
    "remote_containers": os.environ.get("REMOTE_CONTAINERS", ""),
    "dotfiles_role": os.environ.get("DOTFILES_ROLE", ""),
    "dotfiles_hostname": os.environ.get("DOTFILES_HOSTNAME", ""),
    "user": run("id -un", "unknown"),
    "uid": run("id -u", "unknown"),
    "home": os.environ.get("HOME", ""),
    "op_installed": bool(run("command -v op")),
    "op_version": run("op --version"),
    "op_authenticated": bool_cmd("op whoami"),
    "op_account": run("op whoami | head -1"),
    "docker_installed": bool(run("command -v docker")),
    "docker_version": run("docker --version"),
    "git_installed": bool(run("command -v git")),
    "git_version": run("git --version"),
    "age_installed": bool(run("command -v age")),
    "age_version": run("age --version"),
    "age_key_present": os.path.isfile(os.path.expanduser("~/.config/age/key.txt")),
    "outbound_https": bool_cmd("curl -fsS --max-time 5 https://1.1.1.1"),
}

with open(dest, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
}

case "${MODE}" in
  build-time)
    write_probe "build-time" "${BUILD_FILE}"
    echo "Primordial image probe written to ${BUILD_FILE}"
    cat "${BUILD_FILE}"
    ;;
  runtime)
    write_probe "runtime" "${OUT_FILE}"
    echo "Primordial runtime probe written to ${OUT_FILE}"
    ;;
  *)
    echo "Usage: probe-env.sh [build-time|runtime]" >&2
    exit 1
    ;;
esac
