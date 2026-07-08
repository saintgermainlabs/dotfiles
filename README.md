# dotfiles

Personal dotfiles for Ubuntu hosts, managed with [Chezmoi](https://www.chezmoi.io/) and [Mise](https://mise.jdx.dev/).

## Supported roles

|Role|Use case|Notes|
|---|---|---|
|`laptop`|Ubuntu desktop/workstation|GUI tools, Nautilus templates, desktop helper scripts|
|`server`|Hetzner/VPS production|Minimal CLI footprint, Docker/server aliases|
|`vm`|Ephemeral dev/test VM|Lightweight, disposable|

## Quick start

On a fresh machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply saintgermainlabs/sgdotfiles
```

Or with a role preset (useful for VM provisioning):

```bash
DOTFILES_ROLE=vm sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply saintgermainlabs/sgdotfiles
```

## Manual setup

```bash
git clone https://github.com/saintgermainlabs/sgdotfiles.git ~/sgdotfilesfresh
cd ~/sgdotfilesfresh
chezmoi init --source . --apply
```

After applying, copy the secrets template and fill in real values:

```bash
cp ~/.dotfiles/bash/.env.example ~/.dotfiles/bash/.env
chmod 600 ~/.dotfiles/bash/.env
$EDITOR ~/.dotfiles/bash/.env
```

Set your Git email for the laptop role:

```bash
chezmoi edit ~/.gitconfig
# or edit dot_gitconfig.tmpl in the source tree
```

## Day-to-day workflow

```bash
chezmoi edit ~/.bashrc     # edit source file, not target
chezmoi diff               # preview changes
chezmoi apply --dry-run    # dry run
chezmoi apply              # apply changes
chezmoi update             # pull and apply from remote
```

Check the role assigned to the current host:

```bash
chezmoi data | grep role
```

## How roles work

- `.chezmoi.toml.tmpl` detects the role on first init:
  1. `DOTFILES_ROLE` environment variable
  2. hostname `ubuntu-laptop` → `laptop`
  3. interactive prompt (default `server`)
- `.chezmoidata/roles.toml` defines tools and packages per role.
- `.chezmoiignore.tmpl` skips files that don't belong on the current role.
- `dot_config/mise/config.toml.tmpl` renders the tool list for the current role.
- `dot_config/dotfiles/role-aliases.tmpl` renders role-specific shell aliases.

## Secrets

Real secrets are never committed. Keep them in:

- `~/.dotfiles/dot_dotfiles/bash/.env` (gitignored, sourced by `.bashrc`)
- `~/.dotfiles/secrets/` (gitignored, auto-sourced by `.bashrc`)
- Local chezmoi data overrides

Use `age` or `gpg` for encrypted secrets if needed.

## Testing

Before committing:

```bash
chezmoi diff
chezmoi apply --dry-run
chezmoi apply
chezmoi doctor
```
