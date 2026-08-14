# Remote Hermes shell module

Bash/Zsh helpers that SSH to your Coolify host and run commands inside the
Hermes Agent app container. Useful for running `hermes …` remotely and for
downloading, editing, and re-uploading `config.yaml`.

## Requirements

- `ssh` configured for host `ubuntu` (override with `HERMES_SSH_HOST`)
- Docker access on that host for your SSH user
- A running Hermes Coolify service (or a container named `hermes`)

## Enable

In `home/.chezmoidata/modules.toml`:

```toml
[modules.hermes]
enabled = true
```

Then:

```bash
chezmoi apply
exec bash -l
hm_status
```

## Everyday usage

```bash
# Any Hermes CLI command, remotely
hm skills list
hm skills search weather
hm plugins list
hm gateway status

# Install a skill
hm_skill_install official/research/arxiv
hm_skill_install skills-sh/anthropics/skills/pdf --force

# Remove a skill (--yes for scripts)
hm_skill_remove gif-search --dry-run
hm_skill_remove gif-search --yes

# Or the short aliases
hmsi official/research/arxiv
hmsr gif-search --yes

# Plugins
hm_plugin_install owner/repo

# Shell / arbitrary commands in the container
hm_sh
hm_exec ls /home
```

## Config download / edit / upload

Hermes stores configuration as YAML at `/home/config.yaml` inside the
container (then `/home/.hermes/config.yaml`, then `hermes config path`).

```bash
# Download to ~/.cache/hermes/config.yaml
hm_config_get

# Download to a specific path
hm_config_get ~/Downloads/hermes-config.yaml

# Edit locally in Sublime Text (default), validate YAML, then prompt to upload
hm_config_edit
hm_config_edit --editor nano
hm_config_edit --editor vscode

# Upload a previously edited file (creates a timestamped backup in the container)
hm_config_put ~/.cache/hermes/config.yaml
```

The default editor is **Sublime Text**. Persist an override in
`~/.config/hermes/environment` (see `hermes.env.example`):

```bash
mkdir -p ~/.config/hermes
cp ~/.dotfiles/modules/hermes/hermes.env.example ~/.config/hermes/environment
chmod 0600 ~/.config/hermes/environment
# HERMES_CONFIG_EDITOR="/usr/bin/subl -w"
```

Do not use these helpers for `.env` — that file holds API keys.

## Discovery

If `HERMES_APP_CONTAINER` is unset, the module picks a running container named
`hermes`, `hermes-<id>`, or `hermes-agent-<id>`, skipping `tailscale`,
`searxng`, `browser`, and `sandbox` sidecars. Image names containing
`hermes-agent` are a fallback. After a Coolify redeploy:

```bash
hm_refresh
```

Or pin the name in `~/.config/hermes/environment` (see `hermes.env.example`).

## Function reference

| Function | Purpose |
| --- | --- |
| `hm` | Run `hermes …` in the remote container |
| `hm_exec` | Run any command in the container |
| `hm_sh` | Interactive shell |
| `hm_skill_install` | `hermes skills install` |
| `hm_skill_remove` | `hermes skills uninstall` |
| `hm_skill_search` | Search skill registries |
| `hm_skill_list` | List skills |
| `hm_skill_info` | `hermes skills inspect` |
| `hm_skill_update` | Update managed skills |
| `hm_plugin_install` | Install a plugin |
| `hm_plugin_list` | List plugins |
| `hm_config_path` | Print the container path to `config.yaml` |
| `hm_config_get` | Download `config.yaml` |
| `hm_config_put` | Upload `config.yaml` (with backup) |
| `hm_config_edit` | Download, edit locally, optionally upload |
| `hm_status` | Host + container + gateway |
| `hm_refresh` | Clear cached container name |
| `hm_host` | SSH to the Hermes host |

## Security

- Do not put tokens or API keys in this module.
- Skill and plugin installs can execute third-party code inside Hermes —
  review refs before installing.
- Uploading `config.yaml` replaces the live file after a timestamped backup.
  Hermes may need a gateway restart (`hm gateway restart`) before some
  settings take effect.
