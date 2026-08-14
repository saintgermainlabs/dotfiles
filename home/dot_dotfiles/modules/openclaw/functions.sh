# shellcheck shell=bash
#
# Remote OpenClaw helpers — run CLI commands inside the Coolify OpenClaw
# container over SSH. Compatible with Bash and Zsh.

: "${OPENCLAW_SSH_HOST:=ubuntu}"
: "${OPENCLAW_APP_CONTAINER:=openclaw-syowig5e8r47c96qh26btdc0}"
: "${OPENCLAW_SSH_OPTS:=-o BatchMode=yes}"
# When set to 1, skill installs pass --acknowledge-clawhub-risk (needed for
# non-interactive SSH). Default: auto (1 when stdin is not a TTY).
: "${OPENCLAW_ACK_CLAWHUB_RISK:=}"

_oc_error() {
  printf 'openclaw: %s\n' "$*" >&2
}

_oc_require_ssh() {
  command -v ssh >/dev/null 2>&1 || {
    _oc_error "required command not found: ssh"
    return 127
  }
}

# Quote a single argument for remote bash (bash printf %q).
_oc_quote() {
  printf '%q' "$1"
}

# Build a remotely-safe command string from argv.
_oc_quote_cmd() {
  local _oc_out="" _oc_arg
  for _oc_arg in "$@"; do
    if [ -n "$_oc_out" ]; then
      _oc_out="$_oc_out $(_oc_quote "$_oc_arg")"
    else
      _oc_out="$(_oc_quote "$_oc_arg")"
    fi
  done
  printf '%s' "$_oc_out"
  unset _oc_out _oc_arg
}

# Resolve the OpenClaw app container name (override or live discovery).
_oc_container() {
  if [ -n "${OPENCLAW_APP_CONTAINER:-}" ]; then
    printf '%s' "$OPENCLAW_APP_CONTAINER"
    return 0
  fi
  if [ -n "${_OC_CONTAINER_CACHE:-}" ]; then
    printf '%s' "$_OC_CONTAINER_CACHE"
    return 0
  fi

  _oc_require_ssh || return

  # Prefer the Coolify app container: openclaw-<id>, not sidecars.
  _OC_CONTAINER_CACHE="$(
    # shellcheck disable=SC2086
    ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" \
      "docker ps --format '{{.Names}}'" 2>/dev/null |
      awk '
        /^openclaw-tailscale-/ { next }
        /^openclaw-searxng/ { next }
        /^openclaw-browser/ { next }
        /^openclaw-[a-z0-9]+$/ { print; exit }
      '
  )"

  if [ -z "$_OC_CONTAINER_CACHE" ]; then
    unset _OC_CONTAINER_CACHE
    _oc_error "could not find OpenClaw app container on ${OPENCLAW_SSH_HOST}"
    _oc_error "set OPENCLAW_APP_CONTAINER or check: ssh ${OPENCLAW_SSH_HOST} docker ps"
    return 1
  fi

  printf '%s' "$_OC_CONTAINER_CACHE"
}

# Forget a cached container name (after Coolify redeploy).
oc_refresh() {
  unset _OC_CONTAINER_CACHE
  _oc_container
}

# SSH into the OpenClaw host (passthrough args).
oc_host() {
  _oc_require_ssh || return
  # shellcheck disable=SC2086
  ssh $OPENCLAW_SSH_OPTS "$@" "$OPENCLAW_SSH_HOST"
}

# Run a command inside the remote OpenClaw container.
# Usage: oc_exec [-t] <cmd> [args...]
oc_exec() {
  local _oc_tty=0 _oc_container _oc_remote

  if [ "${1:-}" = "-t" ] || [ "${1:-}" = "--tty" ]; then
    _oc_tty=1
    shift
  fi

  if [ "$#" -lt 1 ]; then
    _oc_error "usage: oc_exec [-t] <cmd> [args...]"
    return 2
  fi

  _oc_require_ssh || return
  _oc_container="$(_oc_container)" || return

  if [ "$_oc_tty" -eq 1 ]; then
    _oc_remote="docker exec -it $(_oc_quote "$_oc_container") $(_oc_quote_cmd "$@")"
    # shellcheck disable=SC2086
    ssh -t $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" "$_oc_remote"
  else
    _oc_remote="docker exec $(_oc_quote "$_oc_container") $(_oc_quote_cmd "$@")"
    # shellcheck disable=SC2086
    ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" "$_oc_remote"
  fi
  _oc_status=$?
  unset _oc_tty _oc_container _oc_remote
  return "$_oc_status"
}

# Interactive shell in the OpenClaw container.
oc_sh() {
  if oc_exec sh -c 'test -x /bin/bash' 2>/dev/null; then
    oc_exec -t /bin/bash "$@"
  else
    oc_exec -t /bin/sh "$@"
  fi
}

# Run the remote `openclaw` CLI.
# Usage: oc <openclaw-args...>
#        oc -t <openclaw-args...>   # allocate a TTY (prompts, TUI)
oc() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'EOF'
Usage:
  oc <openclaw-args...>           Run openclaw inside the remote container
  oc -t <openclaw-args...>        Same, with a TTY
  oc_exec [-t] <cmd> [args...]    Run any command in the container
  oc_sh                           Interactive shell in the container
  oc_skill_install <ref> [...]    Install a ClawHub/git/local skill
  oc_skill_remove <slug> [--yes]  Remove an installed workspace skill
  oc_skill_search [query...]      Search ClawHub skills
  oc_skill_list                   List installed/available skills
  oc_plugin_install <spec> [...]  Install an OpenClaw plugin
  oc_status                       Show host, container, and plugin/search bits
  oc_refresh                      Re-discover the app container name

Env:
  OPENCLAW_SSH_HOST          SSH host (default: ubuntu)
  OPENCLAW_APP_CONTAINER     Pin container name (skip discovery)
  OPENCLAW_ACK_CLAWHUB_RISK  1 = always ack ClawHub risk on skill install
EOF
    return 0
  fi

  if [ "${1:-}" = "-t" ] || [ "${1:-}" = "--tty" ]; then
    shift
    oc_exec -t openclaw "$@"
  else
    oc_exec openclaw "$@"
  fi
}

# --- Skills -----------------------------------------------------------------

_oc_skill_ack_flags() {
  if [ "${OPENCLAW_ACK_CLAWHUB_RISK}" = "1" ]; then
    printf '%s\n' --acknowledge-clawhub-risk
    return 0
  fi
  if [ "${OPENCLAW_ACK_CLAWHUB_RISK}" = "0" ]; then
    return 0
  fi
  # Auto: non-interactive sessions cannot answer the risk prompt.
  if [ ! -t 0 ]; then
    printf '%s\n' --acknowledge-clawhub-risk
  fi
}

# Install a skill on the remote OpenClaw instance.
# Usage: oc_skill_install [@owner/slug|git:...|path] [extra openclaw flags...]
oc_skill_install() {
  if [ "$#" -lt 1 ]; then
    _oc_error "usage: oc_skill_install <skill-ref> [options...]"
    _oc_error "example: oc_skill_install @owner/weather"
    _oc_error "example: oc_skill_install bird --global"
    return 2
  fi

  local _oc_ack _oc_args=()
  while IFS= read -r _oc_ack; do
    [ -n "$_oc_ack" ] && _oc_args+=("$_oc_ack")
  done < <(_oc_skill_ack_flags)

  oc_exec openclaw skills install "${_oc_args[@]}" "$@"
  _oc_status=$?
  unset _oc_ack _oc_args
  return "$_oc_status"
}

oc_skill_search() {
  oc_exec openclaw skills search "$@"
}

oc_skill_list() {
  oc_exec openclaw skills list "$@"
}

oc_skill_info() {
  if [ "$#" -lt 1 ]; then
    _oc_error "usage: oc_skill_info <skill>"
    return 2
  fi
  oc_exec openclaw skills info "$@"
}

oc_skill_update() {
  oc_exec openclaw skills update "$@"
}

# Remove an installed workspace skill.
# OpenClaw currently has no `skills uninstall` CLI; this removes the skill
# directory and its ClawHub lockfile entry. If a native uninstall command
# appears later, it is preferred automatically.
# Usage: oc_skill_remove <slug> [--yes|-y] [--dry-run]
oc_skill_remove() {
  local _oc_slug="" _oc_yes=0 _oc_dry=0 _oc_arg _oc_native_help

  for _oc_arg in "$@"; do
    case "$_oc_arg" in
      --yes|-y) _oc_yes=1 ;;
      --dry-run) _oc_dry=1 ;;
      -h|--help)
        _oc_error "usage: oc_skill_remove <slug> [--yes|-y] [--dry-run]"
        unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
        return 2
        ;;
      -*)
        _oc_error "unknown option: $_oc_arg"
        _oc_error "usage: oc_skill_remove <slug> [--yes|-y] [--dry-run]"
        unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
        return 2
        ;;
      *)
        if [ -n "$_oc_slug" ]; then
          _oc_error "usage: oc_skill_remove <slug> [--yes|-y] [--dry-run]"
          unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
          return 2
        fi
        _oc_slug="$_oc_arg"
        ;;
    esac
  done

  if [ -z "$_oc_slug" ]; then
    _oc_error "usage: oc_skill_remove <slug> [--yes|-y] [--dry-run]"
    unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
    return 2
  fi

  # Prefer native uninstall when OpenClaw ships it.
  _oc_native_help="$(oc_exec openclaw skills uninstall --help 2>&1 || true)"
  case "$_oc_native_help" in
    *"Usage: openclaw skills uninstall"*)
      if [ "$_oc_dry" -eq 1 ]; then
        printf 'Would run: openclaw skills uninstall %s\n' "$_oc_slug"
        unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
        return 0
      fi
      if [ "$_oc_yes" -eq 1 ]; then
        oc_exec openclaw skills uninstall --yes "$_oc_slug"
      elif [ -t 0 ]; then
        oc_exec -t openclaw skills uninstall "$_oc_slug"
      else
        oc_exec openclaw skills uninstall --yes "$_oc_slug"
      fi
      _oc_status=$?
      unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
      return "$_oc_status"
      ;;
  esac

  # Reject path traversal / odd names before touching the remote FS.
  case "$_oc_slug" in
    *[!A-Za-z0-9._-]*|.*|*\.\.*)
      _oc_error "invalid skill slug: $_oc_slug"
      unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
      return 2
      ;;
  esac

  if [ "$_oc_yes" -ne 1 ] && [ "$_oc_dry" -ne 1 ]; then
    if [ -t 0 ]; then
      printf 'Remove remote skill %s from workspace? [y/N] ' "$_oc_slug"
      local _oc_answer
      read -r _oc_answer
      case "$_oc_answer" in
        y|Y|yes|YES) ;;
        *)
          printf 'Cancelled.\n'
          unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help _oc_answer
          return 1
          ;;
      esac
      unset _oc_answer
    else
      _oc_error "non-interactive remove requires --yes"
      unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
      return 2
    fi
  fi

  oc_exec python3 -c '
import json, os, shutil, sys
from pathlib import Path

slug = sys.argv[1]
dry = sys.argv[2] == "1"
root = Path("/data/workspace")
skills_dir = root / "skills" / slug
lock_path = root / ".clawhub" / "lock.json"

if not slug or any(c in slug for c in "/\\\\") or ".." in slug or slug.startswith("."):
    raise SystemExit(f"refusing unsafe slug: {slug!r}")

removed_dir = False
removed_lock = False

if skills_dir.exists():
    # Ensure resolved path stays under workspace/skills
    skills_root = (root / "skills").resolve()
    resolved = skills_dir.resolve()
    if skills_root not in resolved.parents and resolved != skills_root:
        raise SystemExit(f"refusing path outside skills root: {resolved}")
    if dry:
        print(f"would remove dir: {skills_dir}")
    else:
        shutil.rmtree(resolved)
        print(f"removed dir: {skills_dir}")
    removed_dir = True
else:
    print(f"no skill dir: {skills_dir}")

if lock_path.is_file():
    data = json.loads(lock_path.read_text())
    skills = data.get("skills")
    if isinstance(skills, dict) and slug in skills:
        if dry:
            print(f"would remove lock entry: {slug}")
        else:
            del skills[slug]
            tmp = lock_path.with_suffix(".json.tmp")
            tmp.write_text(json.dumps(data, indent=2) + chr(10))
            os.chmod(tmp, 0o600)
            tmp.replace(lock_path)
            print(f"removed lock entry: {slug}")
        removed_lock = True
    else:
        print(f"no lock entry: {slug}")
else:
    print(f"no lockfile: {lock_path}")

if not removed_dir and not removed_lock:
    raise SystemExit(f"skill not found: {slug}")
' "$_oc_slug" "$_oc_dry"

  _oc_status=$?
  unset _oc_slug _oc_yes _oc_dry _oc_arg _oc_native_help
  return "$_oc_status"
}

# --- Plugins ----------------------------------------------------------------

oc_plugin_install() {
  if [ "$#" -lt 1 ]; then
    _oc_error "usage: oc_plugin_install <spec> [options...]"
    _oc_error "example: oc_plugin_install clawhub:@openclaw/searxng-plugin"
    return 2
  fi
  oc_exec openclaw plugins install "$@"
}

oc_plugin_list() {
  oc_exec openclaw plugins list "$@"
}


# --- Configuration ----------------------------------------------------------

# Find the active OpenClaw configuration file inside the remote container.
#
# Usage:
#   oc_config_path
#
# Prints the container path, for example:
#   /data/.openclaw/openclaw.json
oc_config_path() {
  local _oc_container _oc_path

  _oc_require_ssh || return
  _oc_container="$(_oc_container)" || return

  # Check the normal OpenClaw path first, then fall back to discovery.
  _oc_path="$(
    # shellcheck disable=SC2086
    ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" \
      "docker exec $(_oc_quote "$_oc_container") sh -c '
        if [ -f /data/.openclaw/openclaw.json ]; then
          printf \"%s\n\" /data/.openclaw/openclaw.json
        else
          find /data /root /home \
            -type f \
            -name openclaw.json \
            2>/dev/null |
            head -n 1
        fi
      '" 2>/dev/null
  )"

  if [ -z "$_oc_path" ]; then
    _oc_error "could not find openclaw.json inside ${_oc_container}"
    unset _oc_container _oc_path
    return 1
  fi

  printf '%s\n' "$_oc_path"

  unset _oc_container _oc_path
}


# Download openclaw.json from the remote OpenClaw container.
#
# Usage:
#   oc_config_get
#   oc_config_get ~/Downloads/openclaw.json
#
# With no destination, saves to:
#   ~/.cache/openclaw/openclaw.json
oc_config_get() {
  local _oc_container _oc_container_path _oc_dest _oc_remote_tmp

  _oc_require_ssh || return
  command -v scp >/dev/null 2>&1 || {
    _oc_error "required command not found: scp"
    return 127
  }

  _oc_container="$(_oc_container)" || return
  _oc_container_path="$(oc_config_path)" || return

  _oc_dest="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/openclaw/openclaw.json}"
  _oc_remote_tmp="/tmp/openclaw-config-${USER:-user}-$$.json"

  mkdir -p "$(dirname "$_oc_dest")" || return

  printf 'Downloading %s:%s\n' "$_oc_container" "$_oc_container_path"

  # First copy from container -> remote host.
  # shellcheck disable=SC2086
  ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" \
    "docker cp \
      $(_oc_quote "${_oc_container}:${_oc_container_path}") \
      $(_oc_quote "$_oc_remote_tmp")" || {
        _oc_error "failed to copy config out of container"
        unset _oc_container _oc_container_path _oc_dest _oc_remote_tmp
        return 1
      }

  # Then copy remote host -> local laptop.
  # shellcheck disable=SC2086
  scp $OPENCLAW_SSH_OPTS \
    "${OPENCLAW_SSH_HOST}:${_oc_remote_tmp}" \
    "$_oc_dest"
  _oc_status=$?

  # Clean up the temporary remote file regardless of scp result.
  # shellcheck disable=SC2086
  ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" \
    "rm -f $(_oc_quote "$_oc_remote_tmp")" >/dev/null 2>&1 || true

  if [ "$_oc_status" -ne 0 ]; then
    _oc_error "failed to download config"
    unset _oc_container _oc_container_path _oc_dest _oc_remote_tmp
    return "$_oc_status"
  fi

  printf 'Saved: %s\n' "$_oc_dest"

  unset _oc_container _oc_container_path _oc_dest _oc_remote_tmp
}


# Upload a local openclaw.json into the remote OpenClaw container.
#
# A timestamped backup is created inside the container before replacement.
#
# Usage:
#   oc_config_put ~/.cache/openclaw/openclaw.json
oc_config_put() {
  local _oc_source _oc_container _oc_container_path
  local _oc_remote_tmp _oc_backup _oc_timestamp

  if [ "$#" -ne 1 ]; then
    _oc_error "usage: oc_config_put <local-openclaw.json>"
    return 2
  fi

  _oc_source="$1"

  if [ ! -f "$_oc_source" ]; then
    _oc_error "file not found: $_oc_source"
    unset _oc_source
    return 1
  fi

  _oc_require_ssh || return
  command -v scp >/dev/null 2>&1 || {
    _oc_error "required command not found: scp"
    return 127
  }

  # Validate JSON locally before uploading.
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$_oc_source" >/dev/null 2>&1 || {
      _oc_error "refusing upload: invalid JSON"
      unset _oc_source
      return 1
    }
  fi

  _oc_container="$(_oc_container)" || return
  _oc_container_path="$(oc_config_path)" || return

  _oc_timestamp="$(date '+%Y%m%d-%H%M%S')"
  _oc_backup="${_oc_container_path}.bak-${_oc_timestamp}"
  _oc_remote_tmp="/tmp/openclaw-config-${USER:-user}-$$.json"

  printf 'Uploading %s\n' "$_oc_source"

  # Laptop -> remote host.
  # shellcheck disable=SC2086
  scp $OPENCLAW_SSH_OPTS \
    "$_oc_source" \
    "${OPENCLAW_SSH_HOST}:${_oc_remote_tmp}" || {
      _oc_error "failed to upload temporary config"
      unset _oc_source _oc_container _oc_container_path
      unset _oc_remote_tmp _oc_backup _oc_timestamp
      return 1
    }

  # Backup existing config, then remote host -> container.
  # shellcheck disable=SC2086
  ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" "
    set -e

    docker exec $(_oc_quote "$_oc_container") \
      cp \
      $(_oc_quote "$_oc_container_path") \
      $(_oc_quote "$_oc_backup")

    docker cp \
      $(_oc_quote "$_oc_remote_tmp") \
      $(_oc_quote "${_oc_container}:${_oc_container_path}")

    rm -f $(_oc_quote "$_oc_remote_tmp")
  "
  _oc_status=$?

  if [ "$_oc_status" -ne 0 ]; then
    _oc_error "failed to install config"
    unset _oc_source _oc_container _oc_container_path
    unset _oc_remote_tmp _oc_backup _oc_timestamp
    return "$_oc_status"
  fi

  printf 'Updated: %s:%s\n' "$_oc_container" "$_oc_container_path"
  printf 'Backup:  %s:%s\n' "$_oc_container" "$_oc_backup"

  unset _oc_source _oc_container _oc_container_path
  unset _oc_remote_tmp _oc_backup _oc_timestamp
}


# Download OpenClaw config, edit it locally, validate it, then optionally
# upload it back into the remote container.
#
# Usage:
#   oc_config_edit
#   oc_config_edit --editor nano
#   oc_config_edit --editor vscode
#
# Editors: sublime (default), nano, vscode.
#
# Optional editor override:
#   OPENCLAW_CONFIG_EDITOR="code -w" oc_config_edit
#
# The local working copy is retained at:
#   ~/.cache/openclaw/openclaw.json
oc_config_edit() {
  local _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty

  _oc_file="${XDG_CACHE_HOME:-$HOME/.cache}/openclaw/openclaw.json"
  _oc_editor_name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --editor)
        if [ "$#" -lt 2 ]; then
          _oc_error "missing value for --editor"
          _oc_error "usage: oc_config_edit [--editor sublime|nano|vscode]"
          return 2
        fi
        _oc_editor_name="$2"
        shift 2
        ;;
      --editor=*)
        _oc_editor_name="${1#--editor=}"
        shift
        ;;
      *)
        _oc_error "unknown argument: $1"
        _oc_error "usage: oc_config_edit [--editor sublime|nano|vscode]"
        return 2
        ;;
    esac
  done

  # Resolve editor: --editor flag > OPENCLAW_CONFIG_EDITOR > default.
  if [ -n "$_oc_editor_name" ]; then
    case "$_oc_editor_name" in
      sublime)  _oc_editor="subl -w" ;;
      nano)     _oc_editor="nano" ;;
      vscode)   _oc_editor="code -w" ;;
      *)
        _oc_error "unknown editor: $_oc_editor_name"
        _oc_error "choose one of: sublime, nano, vscode"
        return 2
        ;;
    esac
  else
    _oc_editor="${OPENCLAW_CONFIG_EDITOR:-subl -w}"
  fi

  _oc_bin="${_oc_editor%% *}"
  if ! command -v "$_oc_bin" >/dev/null 2>&1; then
    _oc_error "editor not found: $_oc_bin"
    _oc_error "try: oc_config_edit --editor nano"
    unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
    return 127
  fi

  oc_config_get "$_oc_file" || {
    unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
    return
  }

  printf '\nOpening OpenClaw config in %s...\n' "$_oc_bin"
  printf 'Local file: %s\n\n' "$_oc_file"

  # Check whether the editor can get a terminal: stdin when it's a TTY, else
  # the controlling terminal (so TUI editors like nano work under piped or
  # agent shells where stdin isn't a TTY).
  _oc_have_tty=false
  if [ -t 0 ]; then
    _oc_have_tty=true
  elif exec 3< /dev/tty 2>/dev/null; then
    exec 3<&-
    _oc_have_tty=true
  fi

  if [ -t 0 ]; then
    # shellcheck disable=SC2086
    $_oc_editor "$_oc_file"
  elif [ "$_oc_have_tty" = true ]; then
    # shellcheck disable=SC2086
    $_oc_editor "$_oc_file" < /dev/tty
  else
    # No controlling terminal — best effort (GUI editors may still work).
    # shellcheck disable=SC2086
    $_oc_editor "$_oc_file"
  fi
  _oc_status=$?

  if [ "$_oc_status" -ne 0 ]; then
    _oc_error "editor exited with status $_oc_status"
    unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
    return "$_oc_status"
  fi

  # Validate edited JSON before offering upload.
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m json.tool "$_oc_file" >/dev/null 2>&1; then
      _oc_error "edited file is not valid JSON"
      _oc_error "local copy retained at: $_oc_file"
      unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
      return 1
    fi
  fi

  printf '\nJSON validation: OK\n'

  if [ -t 0 ]; then
    printf 'Upload edited config to OpenClaw? [y/N] '
    read -r _oc_answer
  elif [ "$_oc_have_tty" = true ]; then
    printf 'Upload edited config to OpenClaw? [y/N] ' >&2
    read -r _oc_answer < /dev/tty
  else
    _oc_error "not uploading automatically in a non-interactive shell"
    _oc_error "run: oc_config_put $(_oc_quote "$_oc_file")"
    unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
    return 0
  fi

  case "$_oc_answer" in
    y|Y|yes|YES)
      oc_config_put "$_oc_file"
      _oc_status=$?
      ;;
    *)
      printf 'Not uploaded.\n'
      printf 'Edited file retained at: %s\n' "$_oc_file"
      _oc_status=0
      ;;
  esac

  unset _oc_file _oc_editor _oc_editor_name _oc_answer _oc_bin _oc_have_tty
  return "$_oc_status"
}


# --- Status -----------------------------------------------------------------

oc_status() {
  local _oc_container
  _oc_container="$(_oc_container)" || return

  printf 'SSH host:   %s\n' "$OPENCLAW_SSH_HOST"
  printf 'Container:  %s\n' "$_oc_container"
  printf '\n--- container ---\n'
  # shellcheck disable=SC2086
  ssh $OPENCLAW_SSH_OPTS "$OPENCLAW_SSH_HOST" \
    "docker ps --filter name=$(_oc_quote "$_oc_container") --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
  printf '\n--- openclaw ---\n'
  oc_exec openclaw --version 2>&1 || true
  printf '\n--- web search provider ---\n'
  oc_exec python3 -c '
import json
from pathlib import Path
p = Path("/data/.openclaw/openclaw.json")
if not p.exists():
    print("missing openclaw.json")
else:
    d = json.loads(p.read_text())
    s = d.get("tools", {}).get("web", {}).get("search", {})
    print("provider:", s.get("provider"))
    print("enabled:", s.get("enabled"))
' 2>&1 || true
  unset _oc_container
}


# --- Authenticateion Toools -----------------------------------------------------------------

oc_get_gateway_token() {
  oc_exec printenv OPENCLAW_GATEWAY_TOKEN
}

oc_devices_list() {
  oc_exec openclaw devices list
}

oc_approve_device() {

  if [ "$#" -lt 1 ]; then
    _oc_error "Proviate the request ID"
    _oc_error "example: oc_approve_device <request-id>"
    return 2
  fi

  echo "Approve device $@"
  return 2
    oc_exec openclaw devices approve "$@"
}