# shellcheck shell=bash
#
# Remote Hermes helpers — run CLI commands inside the Coolify Hermes
# container over SSH. Compatible with Bash and Zsh.

: "${HERMES_SSH_HOST:=ubuntu}"
: "${HERMES_APP_CONTAINER:=}"
: "${HERMES_SSH_OPTS:=-o BatchMode=yes}"
# Default editor for hm_config_edit is Sublime Text (`subl -w`).
# Override in ~/.config/hermes/environment, e.g.:
#   HERMES_CONFIG_EDITOR="subl -w"
: "${HERMES_CONFIG_EDITOR:=}"

_hm_error() {
  printf 'hermes: %s\n' "$*" >&2
}

_hm_require_ssh() {
  command -v ssh >/dev/null 2>&1 || {
    _hm_error "required command not found: ssh"
    return 127
  }
}

# Quote a single argument for remote bash (bash printf %q).
_hm_quote() {
  printf '%q' "$1"
}

# Build a remotely-safe command string from argv.
_hm_quote_cmd() {
  local _hm_out="" _hm_arg
  for _hm_arg in "$@"; do
    if [ -n "$_hm_out" ]; then
      _hm_out="$_hm_out $(_hm_quote "$_hm_arg")"
    else
      _hm_out="$(_hm_quote "$_hm_arg")"
    fi
  done
  printf '%s' "$_hm_out"
  unset _hm_out _hm_arg
}

# Locate Sublime Text. Prefer absolute paths so a stripped PATH still works.
_hm_find_sublime() {
  local _hm_candidate _hm_resolved
  for _hm_candidate in \
    "${HERMES_SUBLIME_BIN:-}" \
    /usr/bin/subl \
    /bin/subl \
    /opt/sublime_text/sublime_text \
    /usr/bin/sublime_text \
    subl \
    sublime_text
  do
    [ -n "$_hm_candidate" ] || continue
    if [ -x "$_hm_candidate" ]; then
      printf '%s\n' "$_hm_candidate"
      return 0
    fi
    _hm_resolved="$(command -v "$_hm_candidate" 2>/dev/null)" || true
    if [ -n "$_hm_resolved" ] && [ -x "$_hm_resolved" ]; then
      printf '%s\n' "$_hm_resolved"
      return 0
    fi
  done
  return 1
}

# Resolve the editor command. Default: Sublime Text, waiting for the window.
# Override with HERMES_CONFIG_EDITOR or --editor sublime|nano|vscode.
_hm_resolve_editor() {
  local _hm_name="${1:-}" _hm_bin

  if [ -n "$_hm_name" ]; then
    case "$_hm_name" in
      sublime|subl)
        _hm_bin="$(_hm_find_sublime)" || return 1
        printf '%s -w' "$_hm_bin"
        return 0
        ;;
      nano) printf '%s' "nano"; return 0 ;;
      vscode|code) printf '%s' "code -w"; return 0 ;;
      *)
        _hm_error "unknown editor: $_hm_name"
        _hm_error "choose one of: sublime, nano, vscode"
        return 2
        ;;
    esac
  fi

  if [ -n "${HERMES_CONFIG_EDITOR:-}" ]; then
    printf '%s' "$HERMES_CONFIG_EDITOR"
    return 0
  fi

  _hm_bin="$(_hm_find_sublime)" || return 1
  printf '%s -w' "$_hm_bin"
}

# Reject obviously broken YAML before upload. Uses PyYAML when available;
# otherwise only checks that the file is non-empty UTF-8 text.
_hm_validate_yaml() {
  local _hm_file="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  python3 -c '
import sys
path = sys.argv[1]
try:
    text = open(path, encoding="utf-8").read()
except Exception as exc:
    print(exc, file=sys.stderr)
    sys.exit(1)
if not text.strip():
    print("empty file", file=sys.stderr)
    sys.exit(1)
try:
    import yaml
    yaml.safe_load(text)
except ImportError:
    pass
except Exception as exc:
    print(exc, file=sys.stderr)
    sys.exit(1)
' "$_hm_file"
}

# Resolve the Hermes app container name (override or live discovery).
_hm_container() {
  if [ -n "${HERMES_APP_CONTAINER:-}" ]; then
    printf '%s' "$HERMES_APP_CONTAINER"
    return 0
  fi
  if [ -n "${_HM_CONTAINER_CACHE:-}" ]; then
    printf '%s' "$_HM_CONTAINER_CACHE"
    return 0
  fi

  _hm_require_ssh || return

  # Prefer the Coolify app container: hermes or hermes-<id>, not sidecars.
  _HM_CONTAINER_CACHE="$(
    # shellcheck disable=SC2086
    ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
      "docker ps --format '{{.Names}}\t{{.Image}}'" 2>/dev/null |
      awk -F '\t' '
        $1 ~ /tailscale/ { next }
        $1 ~ /searxng/ { next }
        $1 ~ /browser/ { next }
        $1 ~ /sandbox/ { next }
        $1 == "hermes" { print $1; found=1; exit }
        $1 ~ /^hermes-[a-z0-9]+$/ { print $1; found=1; exit }
        $1 ~ /^hermes-agent-[a-z0-9]+$/ { print $1; found=1; exit }
        $2 ~ /hermes-agent/ { image=$1 }
        END { if (!found && image) print image }
      '
  )"

  if [ -z "$_HM_CONTAINER_CACHE" ]; then
    unset _HM_CONTAINER_CACHE
    _hm_error "could not find Hermes app container on ${HERMES_SSH_HOST}"
    _hm_error "set HERMES_APP_CONTAINER or check: ssh ${HERMES_SSH_HOST} docker ps"
    return 1
  fi

  printf '%s' "$_HM_CONTAINER_CACHE"
}

# Forget a cached container name (after Coolify redeploy).
hm_refresh() {
  unset _HM_CONTAINER_CACHE
  _hm_container
}

# SSH into the Hermes host (passthrough args).
hm_host() {
  _hm_require_ssh || return
  # shellcheck disable=SC2086
  ssh $HERMES_SSH_OPTS "$@" "$HERMES_SSH_HOST"
}

# Run a command inside the remote Hermes container.
# Usage: hm_exec [-t] <cmd> [args...]
hm_exec() {
  local _hm_tty=0 _hm_container _hm_remote

  if [ "${1:-}" = "-t" ] || [ "${1:-}" = "--tty" ]; then
    _hm_tty=1
    shift
  fi

  if [ "$#" -lt 1 ]; then
    _hm_error "usage: hm_exec [-t] <cmd> [args...]"
    return 2
  fi

  _hm_require_ssh || return
  _hm_container="$(_hm_container)" || return

  if [ "$_hm_tty" -eq 1 ]; then
    _hm_remote="docker exec -it $(_hm_quote "$_hm_container") $(_hm_quote_cmd "$@")"
    # shellcheck disable=SC2086
    ssh -t $HERMES_SSH_OPTS "$HERMES_SSH_HOST" "$_hm_remote"
  else
    _hm_remote="docker exec $(_hm_quote "$_hm_container") $(_hm_quote_cmd "$@")"
    # shellcheck disable=SC2086
    ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" "$_hm_remote"
  fi
  _hm_status=$?
  unset _hm_tty _hm_container _hm_remote
  return "$_hm_status"
}

# Interactive shell in the Hermes container.
hm_sh() {
  if hm_exec sh -c 'test -x /bin/bash' 2>/dev/null; then
    hm_exec -t /bin/bash "$@"
  else
    hm_exec -t /bin/sh "$@"
  fi
}

# Run the remote `hermes` CLI.
# Usage: hm <hermes-args...>
#        hm -t <hermes-args...>   # allocate a TTY (prompts, TUI)
hm() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'EOF'
Usage:
  hm <hermes-args...>             Run hermes inside the remote container
  hm -t <hermes-args...>          Same, with a TTY
  hm_exec [-t] <cmd> [args...]    Run any command in the container
  hm_sh                           Interactive shell in the container
  hm_skill_install <ref> [...]    Install a Hermes skill
  hm_skill_remove <slug> [--yes]  Uninstall a Hermes skill
  hm_skill_search [query...]      Search skill registries
  hm_skill_list                   List installed skills
  hm_plugin_install <spec> [...]  Install a Hermes plugin
  hm_config_get [dest]            Download remote config.yaml
  hm_config_put <file>            Upload a local config.yaml
  hm_config_edit [--editor ...]   Download, edit locally, optionally upload
  hm_status                       Show host, container, and hermes status
  hwedit [file]                   Hermes Workspace (ar4vlr51...): fzf-pick /opt/data file, edit, upload (hwedit -h)
  hm_refresh                      Re-discover the app container name

Env:
  HERMES_SSH_HOST          SSH host (default: ubuntu)
  HERMES_APP_CONTAINER     Pin container name (skip discovery)
  HERMES_CONFIG_EDITOR     Editor command (default: Sublime Text, subl -w)
EOF
    return 0
  fi

  if [ "${1:-}" = "-t" ] || [ "${1:-}" = "--tty" ]; then
    shift
    hm_exec -t hermes "$@"
  else
    hm_exec hermes "$@"
  fi
}

# --- Skills -----------------------------------------------------------------

# Install a skill on the remote Hermes instance.
# Usage: hm_skill_install <skill-ref> [extra hermes flags...]
hm_skill_install() {
  if [ "$#" -lt 1 ]; then
    _hm_error "usage: hm_skill_install <skill-ref> [options...]"
    _hm_error "example: hm_skill_install official/research/arxiv"
    _hm_error "example: hm_skill_install skills-sh/anthropics/skills/pdf --force"
    return 2
  fi
  hm_exec hermes skills install "$@"
}

hm_skill_search() {
  hm_exec hermes skills search "$@"
}

hm_skill_list() {
  hm_exec hermes skills list "$@"
}

hm_skill_info() {
  if [ "$#" -lt 1 ]; then
    _hm_error "usage: hm_skill_info <skill>"
    return 2
  fi
  hm_exec hermes skills inspect "$@"
}

hm_skill_update() {
  hm_exec hermes skills update "$@"
}

# Remove an installed skill via the native Hermes CLI.
# Usage: hm_skill_remove <slug> [--yes|-y] [--dry-run]
hm_skill_remove() {
  local _hm_slug="" _hm_yes=0 _hm_dry=0 _hm_arg

  for _hm_arg in "$@"; do
    case "$_hm_arg" in
      --yes|-y) _hm_yes=1 ;;
      --dry-run) _hm_dry=1 ;;
      -h|--help)
        _hm_error "usage: hm_skill_remove <slug> [--yes|-y] [--dry-run]"
        unset _hm_slug _hm_yes _hm_dry _hm_arg
        return 2
        ;;
      -*)
        _hm_error "unknown option: $_hm_arg"
        _hm_error "usage: hm_skill_remove <slug> [--yes|-y] [--dry-run]"
        unset _hm_slug _hm_yes _hm_dry _hm_arg
        return 2
        ;;
      *)
        if [ -n "$_hm_slug" ]; then
          _hm_error "usage: hm_skill_remove <slug> [--yes|-y] [--dry-run]"
          unset _hm_slug _hm_yes _hm_dry _hm_arg
          return 2
        fi
        _hm_slug="$_hm_arg"
        ;;
    esac
  done

  if [ -z "$_hm_slug" ]; then
    _hm_error "usage: hm_skill_remove <slug> [--yes|-y] [--dry-run]"
    unset _hm_slug _hm_yes _hm_dry _hm_arg
    return 2
  fi

  if [ "$_hm_dry" -eq 1 ]; then
    printf 'Would run: hermes skills uninstall %s\n' "$_hm_slug"
    unset _hm_slug _hm_yes _hm_dry _hm_arg
    return 0
  fi

  if [ "$_hm_yes" -eq 1 ]; then
    hm_exec hermes skills uninstall --yes "$_hm_slug"
  elif [ -t 0 ]; then
    hm_exec -t hermes skills uninstall "$_hm_slug"
  else
    hm_exec hermes skills uninstall --yes "$_hm_slug"
  fi
  _hm_status=$?
  unset _hm_slug _hm_yes _hm_dry _hm_arg
  return "$_hm_status"
}

# --- Plugins ----------------------------------------------------------------

hm_plugin_install() {
  if [ "$#" -lt 1 ]; then
    _hm_error "usage: hm_plugin_install <spec> [options...]"
    _hm_error "example: hm_plugin_install owner/repo"
    return 2
  fi
  hm_exec hermes plugins install "$@"
}

hm_plugin_list() {
  hm_exec hermes plugins list "$@"
}


# --- Configuration ----------------------------------------------------------

# Find the active Hermes configuration file inside the remote container.
#
# Usage:
#   hm_config_path
#
# Prints the container path, for example:
#   /home/config.yaml
hm_config_path() {
  local _hm_container _hm_path

  _hm_require_ssh || return
  _hm_container="$(_hm_container)" || return

  # This Coolify layout keeps Hermes home under /home, then ask the CLI,
  # then fall back to the published-image /opt/data path.
  _hm_path="$(
    # shellcheck disable=SC2086
    ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
      "docker exec $(_hm_quote "$_hm_container") sh -c '
        if [ -f /home/config.yaml ]; then
          printf \"%s\\n\" /home/config.yaml
        elif [ -f /home/.hermes/config.yaml ]; then
          printf \"%s\\n\" /home/.hermes/config.yaml
        else
          found=\$(find /home -type f -name config.yaml 2>/dev/null | head -n 1)
          if [ -n \"\$found\" ]; then
            printf \"%s\\n\" \"\$found\"
          fi
        fi
      '" 2>/dev/null
  )"

  if [ -z "$_hm_path" ]; then
    _hm_path="$(hm_exec hermes config path 2>/dev/null | tr -d '\r' | head -n 1)"
  fi

  if [ -z "$_hm_path" ]; then
    _hm_path="$(
      # shellcheck disable=SC2086
      ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
        "docker exec $(_hm_quote "$_hm_container") sh -c '
          if [ -f /opt/data/config.yaml ]; then
            printf \"%s\\n\" /opt/data/config.yaml
          elif [ -f /opt/data/.hermes/config.yaml ]; then
            printf \"%s\\n\" /opt/data/.hermes/config.yaml
          else
            find /opt/data /root \
              -type f \
              -name config.yaml \
              2>/dev/null |
              head -n 1
          fi
        '" 2>/dev/null
    )"
  fi

  if [ -z "$_hm_path" ]; then
    _hm_error "could not find config.yaml inside ${_hm_container}"
    unset _hm_container _hm_path
    return 1
  fi

  printf '%s\n' "$_hm_path"

  unset _hm_container _hm_path
}


# Download config.yaml from the remote Hermes container.
#
# Usage:
#   hm_config_get
#   hm_config_get ~/Downloads/config.yaml
#
# With no destination, saves to:
#   ~/.cache/hermes/config.yaml
hm_config_get() {
  local _hm_container _hm_container_path _hm_dest _hm_remote_tmp

  _hm_require_ssh || return
  command -v scp >/dev/null 2>&1 || {
    _hm_error "required command not found: scp"
    return 127
  }

  _hm_container="$(_hm_container)" || return
  _hm_container_path="$(hm_config_path)" || return

  _hm_dest="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/hermes/config.yaml}"
  _hm_remote_tmp="/tmp/hermes-config-${USER:-user}-$$.yaml"

  mkdir -p "$(dirname "$_hm_dest")" || return

  printf 'Downloading %s:%s\n' "$_hm_container" "$_hm_container_path"

  # First copy from container -> remote host.
  # shellcheck disable=SC2086
  ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
    "docker cp \
      $(_hm_quote "${_hm_container}:${_hm_container_path}") \
      $(_hm_quote "$_hm_remote_tmp")" || {
        _hm_error "failed to copy config out of container"
        unset _hm_container _hm_container_path _hm_dest _hm_remote_tmp
        return 1
      }

  # Then copy remote host -> local laptop.
  # shellcheck disable=SC2086
  scp $HERMES_SSH_OPTS \
    "${HERMES_SSH_HOST}:${_hm_remote_tmp}" \
    "$_hm_dest"
  _hm_status=$?

  # Clean up the temporary remote file regardless of scp result.
  # shellcheck disable=SC2086
  ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
    "rm -f $(_hm_quote "$_hm_remote_tmp")" >/dev/null 2>&1 || true

  if [ "$_hm_status" -ne 0 ]; then
    _hm_error "failed to download config"
    unset _hm_container _hm_container_path _hm_dest _hm_remote_tmp
    return "$_hm_status"
  fi

  printf 'Saved: %s\n' "$_hm_dest"

  unset _hm_container _hm_container_path _hm_dest _hm_remote_tmp
}


# Upload a local config.yaml into the remote Hermes container.
#
# A timestamped backup is created inside the container before replacement.
#
# Usage:
#   hm_config_put ~/.cache/hermes/config.yaml
hm_config_put() {
  local _hm_source _hm_container _hm_container_path
  local _hm_remote_tmp _hm_backup _hm_timestamp

  if [ "$#" -ne 1 ]; then
    _hm_error "usage: hm_config_put <local-config.yaml>"
    return 2
  fi

  _hm_source="$1"

  if [ ! -f "$_hm_source" ]; then
    _hm_error "file not found: $_hm_source"
    unset _hm_source
    return 1
  fi

  _hm_require_ssh || return
  command -v scp >/dev/null 2>&1 || {
    _hm_error "required command not found: scp"
    return 127
  }

  _hm_validate_yaml "$_hm_source" || {
    _hm_error "refusing upload: invalid YAML"
    unset _hm_source
    return 1
  }

  _hm_container="$(_hm_container)" || return
  _hm_container_path="$(hm_config_path)" || return

  _hm_timestamp="$(date '+%Y%m%d-%H%M%S')"
  _hm_backup="${_hm_container_path}.bak-${_hm_timestamp}"
  _hm_remote_tmp="/tmp/hermes-config-${USER:-user}-$$.yaml"

  printf 'Uploading %s\n' "$_hm_source"

  # Laptop -> remote host.
  # shellcheck disable=SC2086
  scp $HERMES_SSH_OPTS \
    "$_hm_source" \
    "${HERMES_SSH_HOST}:${_hm_remote_tmp}" || {
      _hm_error "failed to upload temporary config"
      unset _hm_source _hm_container _hm_container_path
      unset _hm_remote_tmp _hm_backup _hm_timestamp
      return 1
    }

  # Backup existing config, then remote host -> container.
  # shellcheck disable=SC2086
  ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" "
    set -e

    docker exec $(_hm_quote "$_hm_container") \
      cp \
      $(_hm_quote "$_hm_container_path") \
      $(_hm_quote "$_hm_backup")

    docker cp \
      $(_hm_quote "$_hm_remote_tmp") \
      $(_hm_quote "${_hm_container}:${_hm_container_path}")

    rm -f $(_hm_quote "$_hm_remote_tmp")
  "
  _hm_status=$?

  if [ "$_hm_status" -ne 0 ]; then
    _hm_error "failed to install config"
    unset _hm_source _hm_container _hm_container_path
    unset _hm_remote_tmp _hm_backup _hm_timestamp
    return "$_hm_status"
  fi

  printf 'Updated: %s:%s\n' "$_hm_container" "$_hm_container_path"
  printf 'Backup:  %s:%s\n' "$_hm_container" "$_hm_backup"

  unset _hm_source _hm_container _hm_container_path
  unset _hm_remote_tmp _hm_backup _hm_timestamp
}


# Download Hermes config, edit it locally, validate it, then optionally
# upload it back into the remote container.
#
# Usage:
#   hm_config_edit
#   hm_config_edit --editor nano
#   hm_config_edit --editor vscode
#
# Default editor is Sublime Text (`subl -w`). Override with:
#   HERMES_CONFIG_EDITOR in ~/.config/hermes/environment
#   HERMES_CONFIG_EDITOR="code -w" hm_config_edit
#   hm_config_edit --editor nano
#
# The local working copy is retained at:
#   ~/.cache/hermes/config.yaml
hm_config_edit() {
  local _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty

  _hm_file="${XDG_CACHE_HOME:-$HOME/.cache}/hermes/config.yaml"
  _hm_editor_name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --editor)
        if [ "$#" -lt 2 ]; then
          _hm_error "missing value for --editor"
          _hm_error "usage: hm_config_edit [--editor sublime|nano|vscode]"
          return 2
        fi
        _hm_editor_name="$2"
        shift 2
        ;;
      --editor=*)
        _hm_editor_name="${1#--editor=}"
        shift
        ;;
      *)
        _hm_error "unknown argument: $1"
        _hm_error "usage: hm_config_edit [--editor sublime|nano|vscode]"
        return 2
        ;;
    esac
  done

  # Resolve editor: --editor flag > HERMES_CONFIG_EDITOR > Sublime Text.
  _hm_editor="$(_hm_resolve_editor "$_hm_editor_name")" || {
    _hm_status=$?
    if [ "$_hm_status" -eq 2 ]; then
      unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
      return 2
    fi
    _hm_error "Sublime Text not found (tried /usr/bin/subl and sublime_text)"
    _hm_error "set HERMES_CONFIG_EDITOR in ~/.config/hermes/environment"
    _hm_error "example: HERMES_CONFIG_EDITOR=\"/usr/bin/subl -w\""
    _hm_error "or run: hm_config_edit --editor nano"
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return 127
  }

  _hm_bin="${_hm_editor%% *}"
  if [ ! -x "$_hm_bin" ] && ! command -v "$_hm_bin" >/dev/null 2>&1; then
    _hm_error "editor not found: $_hm_bin"
    _hm_error "set HERMES_CONFIG_EDITOR in ~/.config/hermes/environment"
    _hm_error "example: HERMES_CONFIG_EDITOR=\"/usr/bin/subl -w\""
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return 127
  fi

  hm_config_get "$_hm_file" || {
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return
  }

  printf '\nOpening Hermes config in %s...\n' "$_hm_bin"
  printf 'Local file: %s\n\n' "$_hm_file"

  # Check whether the editor can get a terminal: stdin when it's a TTY, else
  # the controlling terminal (so TUI editors like nano work under piped or
  # agent shells where stdin isn't a TTY).
  _hm_have_tty=false
  if [ -t 0 ]; then
    _hm_have_tty=true
  elif exec 3< /dev/tty 2>/dev/null; then
    exec 3<&-
    _hm_have_tty=true
  fi

  if [ -t 0 ]; then
    # shellcheck disable=SC2086
    $_hm_editor "$_hm_file"
  elif [ "$_hm_have_tty" = true ]; then
    # shellcheck disable=SC2086
    $_hm_editor "$_hm_file" < /dev/tty
  else
    # No controlling terminal — best effort (GUI editors may still work).
    # shellcheck disable=SC2086
    $_hm_editor "$_hm_file"
  fi
  _hm_status=$?

  if [ "$_hm_status" -ne 0 ]; then
    _hm_error "editor exited with status $_hm_status"
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return "$_hm_status"
  fi

  if ! _hm_validate_yaml "$_hm_file"; then
    _hm_error "edited file is not valid YAML"
    _hm_error "local copy retained at: $_hm_file"
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return 1
  fi

  printf '\nYAML validation: OK\n'

  if [ -t 0 ]; then
    printf 'Upload edited config to Hermes? [y/N] '
    read -r _hm_answer
  elif [ "$_hm_have_tty" = true ]; then
    printf 'Upload edited config to Hermes? [y/N] ' >&2
    read -r _hm_answer < /dev/tty
  else
    _hm_error "not uploading automatically in a non-interactive shell"
    _hm_error "run: hm_config_put $(_hm_quote "$_hm_file")"
    unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
    return 0
  fi

  case "$_hm_answer" in
    y|Y|yes|YES)
      hm_config_put "$_hm_file"
      _hm_status=$?
      ;;
    *)
      printf 'Not uploaded.\n'
      printf 'Edited file retained at: %s\n' "$_hm_file"
      _hm_status=0
      ;;
  esac

  unset _hm_file _hm_editor _hm_editor_name _hm_answer _hm_bin _hm_have_tty
  return "$_hm_status"
}


# --- Status -----------------------------------------------------------------

hm_status() {
  local _hm_container
  _hm_container="$(_hm_container)" || return

  printf 'SSH host:   %s\n' "$HERMES_SSH_HOST"
  printf 'Container:  %s\n' "$_hm_container"
  printf '\n--- container ---\n'
  # shellcheck disable=SC2086
  ssh $HERMES_SSH_OPTS "$HERMES_SSH_HOST" \
    "docker ps --filter name=$(_hm_quote "$_hm_container") --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
  printf '\n--- hermes ---\n'
  hm_exec hermes version 2>&1 || hm_exec hermes --version 2>&1 || true
  printf '\n--- gateway ---\n'
  hm_exec hermes gateway status 2>&1 || true
  printf '\n--- config ---\n'
  hm_config_path 2>&1 || true
  unset _hm_container
}
