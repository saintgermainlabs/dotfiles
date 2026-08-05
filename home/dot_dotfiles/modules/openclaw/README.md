# Remote OpenClaw shell module

Bash/Zsh helpers that SSH to your Coolify host and run commands inside the
OpenClaw app container. Useful for installing ClawHub skills without logging
into the server by hand.

## Requirements

- `ssh` configured for host `ubuntu` (override with `OPENCLAW_SSH_HOST`)
- Docker access on that host for your SSH user
- A running OpenClaw Coolify service

## Enable

In `home/.chezmoidata/modules.toml`:

```toml
[modules.openclaw]
enabled = true
```

Then:

```bash
chezmoi apply
exec bash -l
oc_status
```

## Everyday usage

```bash
# Any OpenClaw CLI command, remotely
oc skills list
oc skills search weather
oc plugins list

# Install a ClawHub skill (main use case)
oc_skill_install @owner/weather
oc_skill_install bird --global

# Remove a workspace skill (dir + lockfile; --yes for scripts)
oc_skill_remove reddit --dry-run
oc_skill_remove reddit --yes

# Or the short aliases
ocsi @owner/weather
ocsr reddit --yes

# Plugins
oc_plugin_install clawhub:@openclaw/searxng-plugin

# Shell / arbitrary commands in the container
oc_sh
oc_exec ls /data/.openclaw
```

## Discovery

If `OPENCLAW_APP_CONTAINER` is unset, the module picks the first running
container named like `openclaw-<id>`, skipping `tailscale`, `searxng`, and
`browser` sidecars. After a Coolify redeploy:

```bash
oc_refresh
```

Or pin the name in `~/.config/openclaw/environment` (see
`openclaw.env.example`).

## Function reference

| Function | Purpose |
| --- | --- |
| `oc` | Run `openclaw …` in the remote container |
| `oc_exec` | Run any command in the container |
| `oc_sh` | Interactive shell |
| `oc_skill_install` | `openclaw skills install` |
| `oc_skill_remove` | Remove workspace skill dir + lockfile entry |
| `oc_skill_search` | Search ClawHub |
| `oc_skill_list` | List skills |
| `oc_skill_info` | Skill details |
| `oc_skill_update` | Update managed skills |
| `oc_plugin_install` | Install a plugin |
| `oc_plugin_list` | List plugins |
| `oc_status` | Host + container + search provider |
| `oc_refresh` | Clear cached container name |
| `oc_host` | SSH to the OpenClaw host |

## Security

- Do not put tokens or API keys in this module.
- Skill installs from ClawHub can execute third-party code inside OpenClaw —
  review refs before installing.
- Non-interactive installs auto-pass `--acknowledge-clawhub-risk`; set
  `OPENCLAW_ACK_CLAWHUB_RISK=0` to disable that.
