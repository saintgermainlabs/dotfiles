#!/bin/sh
# Bootstrap these dotfiles on a fresh machine.
# Installs mise and chezmoi, then runs chezmoi init --apply.
#
# Usage:
#   sh bootstrap.sh
#   DOTFILES_ROLE=server sh bootstrap.sh
#   DOTFILES_ROLE=vm sh bootstrap.sh
set -eu

# Install mise
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Install chezmoi and apply this repo
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply saintgermainlabs/sgdotfiles
