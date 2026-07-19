#!/usr/bin/env bash
# Shared apt helpers for primordial install scripts.

apt_install() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

apt_pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_apt_packages() {
  local pkg
  local -a missing=()

  for pkg in "$@"; do
    if apt_pkg_installed "${pkg}"; then
      printf '[apt] OK: %s already installed\n' "${pkg}"
    else
      missing+=("${pkg}")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    printf '[apt] All requested packages already installed\n'
    return 0
  fi

  printf '[apt] Installing packages: %s\n' "${missing[*]}"
  apt_install apt-get update
  apt_install apt-get install -y --no-install-recommends "${missing[@]}"
  apt_install rm -rf /var/lib/apt/lists/*
}
