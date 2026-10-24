# shellcheck shell=bash
#
# hwedit — edit config files of the Coolify "Hermes Workspace" deployment
# (hermes-agent + hermes-workspace UI, app uuid ar4vlr51l3v5ikacmyyswbc9).
# Files live in HERMES_HOME (/opt/data) of the hermes-agent-<uuid>-<n> container.
# The container suffix changes on every redeploy, so it is resolved live.
# Compatible with Bash and Zsh.

: "${HWEDIT_SSH_HOST:=${HERMES_SSH_HOST:-ubuntu}}"
: "${HWEDIT_APP_UUID:=ar4vlr51l3v5ikacmyyswbc9}"
: "${HWEDIT_HOME:=/opt/data}"
: "${HWEDIT_EDITOR:=}"

_hw_error() { printf 'hwedit: %s\n' "$*" >&2; }

## @internal
## @category AI & Automation
## @description Resolve the current hermes-agent container for the Coolify app uuid.
_hw_container() {
  local _hw_c
  _hw_c="$(ssh -o BatchMode=yes "$HWEDIT_SSH_HOST" \
    "docker ps --filter 'name=^hermes-agent-${HWEDIT_APP_UUID}' --format '{{.Names}}'" 2>/dev/null | head -n1)"
  if [ -z "$_hw_c" ]; then
    _hw_error "no running hermes-agent-${HWEDIT_APP_UUID}* container on ${HWEDIT_SSH_HOST}"
    return 1
  fi
  printf '%s' "$_hw_c"
}

## @internal
## @category AI & Automation
## @description Run a shell snippet in the agent container (as root, so owner/mode can be preserved).
## @arg $1 string Container name. Remaining args: sh -c script and its positional args.
_hw_exec() {
  local _hw_c="$1"; shift
  ssh -o BatchMode=yes "$HWEDIT_SSH_HOST" "docker exec -i -u 0 $(printf '%q' "$_hw_c") $(printf '%q ' "$@")"
}

## @category AI & Automation
## @description List editable Hermes Workspace config files (relative to /opt/data).
## @usage hwedit_ls
## @see hwedit
hwedit_ls() {
  local _hw_c
  _hw_c="$(_hw_container)" || return
  _hw_exec "$_hw_c" sh -c 'cd "$1" && find . -maxdepth 3 \
      \( -path ./cache -o -path ./sessions -o -path ./skills -o -path ./logs -o -path ./backups \
         -o -path ./installs -o -path ./.cache -o -path ./.local -o -path ./.mem0 -o -path ./plugins \
         -o -path ./secrets -o -path ./runtime -o -path ./cron -o -path ./state -o -path ./kanban \
         -o -path ./pending_messages -o -path ./plugin-update-checks -o -path "./profiles/*/*/*" \) -prune \
      -o -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.md" -o -name "*.toml" -o -name ".env" \) \
      ! -name "*.bak*" ! -name "auth.json" ! -name "gateway_state.json" ! -name "spawn-ledger.json" \
      ! -name "tasks.json" ! -name "workspace-sessions.json" ! -name "channel_directory.json" -print \
    | sed "s#^\./##" | sort' _ "$HWEDIT_HOME"
}

## @internal
## @category AI & Automation
## @description Validate a file by extension (JSON/YAML) using the container python (has PyYAML).
_hw_validate() { # $1 container, $2 local file, $3 remote name
  case "$3" in
    *.json) python3 -m json.tool "$2" >/dev/null ;;
    *.yaml|*.yml)
      _hw_exec "$1" sh -c 'P=/opt/hermes/.venv/bin/python; [ -x "$P" ] || P=python3; "$P" -c "import sys,yaml; yaml.safe_load(sys.stdin)"' < "$2" ;;
    *) return 0 ;;
  esac
}

_hw_sha() { sha256sum "$1" | cut -d' ' -f1; }

_hw_ask() { # $1 prompt -> 0 if yes
  local _hw_a
  if [ -t 0 ]; then printf '%s [y/N] ' "$1"; read -r _hw_a
  elif { exec 3</dev/tty; } 2>/dev/null; then printf '%s [y/N] ' "$1" >&2; read -r _hw_a <&3; exec 3<&-
  else return 1; fi
  case "$_hw_a" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

## @category AI & Automation
## @description Edit a Hermes Workspace config file in Sublime Text and re-upload it if changed.
## @usage hwedit [--dry-run] [--list] [file]
## @example hwedit
## @example hwedit config.yaml
## @example hwedit profiles/coder/SOUL.md
## @example HWEDIT_EDITOR="nano" hwedit .env
## @requires ssh
## @requires fzf
## @see hwedit_ls
hwedit() {
  local _hw_dry=0 _hw_rel="" _hw_c _hw_dir _hw_tmp _hw_before _hw_after _hw_ed _hw_ts _hw_rc
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        cat <<'HELP'
Usage: hwedit [--dry-run] [--list] [file]

Edit a config file inside the Hermes Workspace agent container (HERMES_HOME=/opt/data).
With no file, pick one with fzf. The file is copied to a private temp file (0600),
opened with $HWEDIT_EDITOR (default: subl -w), and uploaded only if it changed:
  - JSON / YAML are validated first (YAML via the container's PyYAML)
  - aborts if the remote file changed while you were editing
  - timestamped backup kept next to it: <file>.bak-hwedit-YYYYmmdd-HHMMSS
  - original owner (hermes:hermes) and mode are preserved
Then offers to restart the agent container (HWEDIT_RESTART=yes|no to skip the prompt).

Options:
  --dry-run   Download only: print container, path, size, sha256; no editor/upload
  --list      List editable files (same as hwedit_ls)

Env:
  HWEDIT_EDITOR     Editor command, must block until closed (default: subl -w)
  HWEDIT_SSH_HOST   SSH host (default: $HERMES_SSH_HOST or ubuntu)
  HWEDIT_APP_UUID   Coolify app uuid (default: ar4vlr51l3v5ikacmyyswbc9)
  HWEDIT_HOME       Remote HERMES_HOME (default: /opt/data)
HELP
        return 0 ;;
      --dry-run|-n) _hw_dry=1; shift ;;
      --list|-l) hwedit_ls; return ;;
      -*) _hw_error "unknown option: $1"; return 2 ;;
      *) _hw_rel="${1#"$HWEDIT_HOME"/}"; shift ;;
    esac
  done

  _hw_c="$(_hw_container)" || return
  if [ -z "$_hw_rel" ]; then
    command -v fzf >/dev/null 2>&1 || { _hw_error "fzf not found; pass a file name (see hwedit --list)"; return 127; }
    _hw_rel="$(hwedit_ls | fzf --prompt='hermes /opt/data> ' --height=40% --reverse)" || return 130
    [ -n "$_hw_rel" ] || return 130
  fi
  case "$_hw_rel" in /*|*..*) _hw_error "path must be relative to $HWEDIT_HOME: $_hw_rel"; return 2 ;; esac

  _hw_dir="$(mktemp -d "${TMPDIR:-/tmp}/hwedit.XXXXXX")" || return
  chmod 700 "$_hw_dir"
  _hw_tmp="$_hw_dir/$(basename "$_hw_rel")"
  ( umask 077; : > "$_hw_tmp" ); chmod 600 "$_hw_tmp"

  if ! _hw_exec "$_hw_c" cat "$HWEDIT_HOME/$_hw_rel" > "$_hw_tmp"; then
    _hw_error "could not read $_hw_c:$HWEDIT_HOME/$_hw_rel"; rm -rf "$_hw_dir"; return 1
  fi
  _hw_before="$(_hw_sha "$_hw_tmp")"

  if [ "$_hw_dry" -eq 1 ]; then
    printf 'Container: %s\nRemote:    %s/%s\nLocal:     %s\nBytes:     %s\nSHA256:    %s\n' \
      "$_hw_c" "$HWEDIT_HOME" "$_hw_rel" "$_hw_tmp" "$(wc -c < "$_hw_tmp" | tr -d ' ')" "$_hw_before"
    rm -rf "$_hw_dir"; return 0
  fi

  _hw_ed="${HWEDIT_EDITOR:-subl -w}"
  printf 'Editing %s:%s/%s with %s (close the file/window to continue)...\n' "$_hw_c" "$HWEDIT_HOME" "$_hw_rel" "$_hw_ed"
  if [ ! -t 0 ] && { exec 3</dev/tty; } 2>/dev/null; then
    exec 3<&-; eval "$_hw_ed \"\$_hw_tmp\"" </dev/tty
  else
    eval "$_hw_ed \"\$_hw_tmp\""
  fi
  _hw_rc=$?
  if [ "$_hw_rc" -ne 0 ]; then _hw_error "editor exited $_hw_rc; nothing uploaded"; rm -rf "$_hw_dir"; return "$_hw_rc"; fi

  _hw_after="$(_hw_sha "$_hw_tmp")"
  if [ "$_hw_before" = "$_hw_after" ]; then
    printf 'No changes; nothing uploaded.\n'; rm -rf "$_hw_dir"; return 0
  fi

  while ! _hw_validate "$_hw_c" "$_hw_tmp" "$_hw_rel"; do
    _hw_error "$_hw_rel failed validation"
    if _hw_ask "Re-open editor to fix?"; then eval "$_hw_ed \"\$_hw_tmp\""
    else _hw_error "not uploaded; your edit is kept at $_hw_tmp"; return 1; fi
  done

  _hw_ts="$(date +%Y%m%d-%H%M%S)"
  # shellcheck disable=SC2016
  if ! _hw_exec "$_hw_c" sh -c '
      set -e; f="$1"; ts="$2"; want="$3"
      cur=$(sha256sum "$f" | cut -d" " -f1)
      [ "$cur" = "$want" ] || { echo "remote file changed since download; aborting" >&2; exit 3; }
      cp -p "$f" "$f.bak-hwedit-$ts"
      t=$(mktemp "$f.hwedit.XXXXXX"); cat > "$t"
      chown --reference="$f" "$t"; chmod --reference="$f" "$t"; mv -f "$t" "$f"
      ls -l "$f"' _ "$HWEDIT_HOME/$_hw_rel" "$_hw_ts" "$_hw_before" < "$_hw_tmp"; then
    _hw_error "upload failed; your edit is kept at $_hw_tmp"; return 1
  fi
  printf 'Uploaded. Backup: %s/%s.bak-hwedit-%s\n' "$HWEDIT_HOME" "$_hw_rel" "$_hw_ts"
  rm -rf "$_hw_dir"

  case "${HWEDIT_RESTART:-ask}" in
    yes) _hw_restart=1 ;; no) _hw_restart=0 ;;
    *) if _hw_ask "Restart $_hw_c now?"; then _hw_restart=1; else _hw_restart=0; fi ;;
  esac
  if [ "$_hw_restart" -eq 1 ]; then
    ssh -o BatchMode=yes "$HWEDIT_SSH_HOST" "docker restart $(printf '%q' "$_hw_c")" >/dev/null && printf 'Restarted %s\n' "$_hw_c"
  fi
  unset _hw_restart
}
