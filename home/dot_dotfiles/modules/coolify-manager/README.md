# Coolify Manager

Bash/Zsh helpers that wrap the [Coolify CLI](https://github.com/coollabsio/coolify-cli)
to find and inspect applications and services. Apps and services are treated as
the same kind of resource for lookup purposes.

## Requirements

- `coolify` CLI installed and authenticated (`coolify context verify`)
- `jq`

## Enable

In `home/.chezmoidata/modules.toml`:

```toml
[modules.coolify-manager]
enabled = true
description = "Coolify CLI helpers for apps/services"
```

Then:

```bash
chezmoi apply
exec bash -l
```

Or run `./install.sh` in this directory for dependency checks.

## Authentication

Create an API token in Coolify at `/security/api-tokens`, then:

```bash
coolify context add -d default https://coolify.example.com <api-token>
coolify context verify
```

Optional overrides live in `~/.config/coolify-manager/environment`
(see `coolify.env.example`). Do not put API tokens there — use the Coolify CLI
config (`~/.config/coolify/config.json`).

## Everyday usage

```bash
# Find a UUID (applications and services)
coolify_find_app name=openclaw
coolify_find_app tag=production
coolify_find_app id=syowig5e8r47c96qh26btdc0

# Server configuration directory on the Coolify host
coolify_find_app_path name=openclaw
# → /data/coolify/applications/<uuid>  or  /data/coolify/services/<uuid>

# Full details (type, uuid, name, server_path, then coolify get)
coolify_app_info name=openclaw

# Short aliases
cfa name=openclaw
cfap name=openclaw
cai name=openclaw
```

Selectors can be combined (AND). A bare token is treated as a UUID when it
looks like one, otherwise as a name.

## Function reference

| Function | Purpose |
| --- | --- |
| `coolify_find_app` | Print the UUID of a matching app/service |
| `coolify_find_app_path` | Print `/data/coolify/{applications\|services}/<uuid>` |
| `coolify_app_info` | Print summary + `coolify app/service get` details |

## Notes

- `coolify_find_app_path` returns the **server-side** Coolify configuration
  directory, not a local path and not the git `base_directory`.
- Tag filtering depends on tags being present in `coolify app/service list`
  JSON. Prefer `id=` or `name=` when tags are missing from list output.
- Override the data root with `COOLIFY_DATA_DIR` (default `/data/coolify`).
- Override the CLI context with `COOLIFY_CONTEXT`.
