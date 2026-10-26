#!/usr/bin/env bash
# remote-banner.sh — "$USER @ REMOTE SERVER" banner for interactive logins on role=remote hosts.
# Sourced (or run) from shell startup; prints nothing for non-interactive shells or non-TTYs.
# Set REMOTE_BANNER=0 to disable.
_remote_banner() {
  [ "${REMOTE_BANNER:-1}" = 0 ] && return 0
  case $- in *i*) ;; *) [ -n "${_RB_FORCE:-}" ] || return 0 ;; esac
  [ -t 1 ] || return 0
  local user shell host
  user="${USER:-$(id -un 2>/dev/null || whoami)}"
  if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh ${ZSH_VERSION}"
  elif [ -n "${BASH_VERSION:-}" ]; then shell="bash ${BASH_VERSION%%(*}"
  else shell="$(basename -- "${0#-}")"; fi
  host="$(hostname 2>/dev/null || uname -n)"
  printf '\033]0;%s @ REMOTE SERVER — %s\007' "$user" "$host"
  local title="${user} @ REMOTE SERVER"
  if command -v figlet >/dev/null 2>&1; then
    printf '\033[1;31m'; figlet -w 160 "$title"; printf '\033[0m'
  else
    local w=$(( ${#title} + 8 )) line
    line="$(printf '%*s' "$w" '' | tr ' ' '=')"
    printf '\033[1;31m%s\n||  %s  ||\n%s\033[0m\n' "$line" "$title" "$line"
  fi
  printf '\033[1;33m  host: %s   shell: %s   uid: %s\033[0m\n\n' "$host" "$shell" "$(id -u)"
}
_remote_banner
unset -f _remote_banner
