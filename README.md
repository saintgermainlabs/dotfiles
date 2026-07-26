# dotfiles

Simplified personal dotfiles managed with [Chezmoi](https://www.chezmoi.io/).
Tool installs, PATH, and environment variables are owned by [mise](https://mise.jdx.dev/)
(and the workstation provisioner), not by this repo.

## Axes

| Axis | Values | Meaning |
|------|--------|---------|
| `role` | `local` \| `remote` | `local` = this laptop; `remote` = headless server |
| `gui` | `true` \| `false` | Whether GUI config modules may apply (defaults: local=true, remote=false) |

## Modules

Toggle modules in [`home/.chezmoidata/modules.toml`](home/.chezmoidata/modules.toml),
then run `chezmoi apply`.

Examples: keep `nautilus` on and `thunar` off, or the reverse.

## Quick start

```bash
# Install chezmoi (or use: python -m provisioner tools)
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"

# Init from this repo (after pushing), or apply from a local checkout:
chezmoi init --apply --source "$PWD"

# Preview
DOTFILES_HOSTNAME=god-Latitude-7390-2-in-1 chezmoi diff
```

Set your hostname in [`home/.chezmoidata/hosts.toml`](home/.chezmoidata/hosts.toml).

## Layout

Chezmoi root is `home/` (see `.chezmoiroot`). Files outside `home/` are never applied to `$HOME`.
