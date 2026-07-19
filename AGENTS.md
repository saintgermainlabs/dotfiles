# AGENTS.md

This repository manages personal and server configuration using Chezmoi and Mise.
Every change must be safe to re-apply with `chezmoi apply`.

## Repository layout

`.chezmoiroot` points Chezmoi at the `home/` subdirectory. Files outside `home/`
(README, bootstrap, docs, this file, etc.) live only in the source repo and are
never applied to `$HOME`.

```text
home/
├── .chezmoidata/          # host, role, tool, package, fragment, module data
├── .chezmoiscripts/       # run_once_* / run_onchange_* scripts (flat, no shared/)
├── .chezmoitemplates/     # reusable template fragments
├── dot_config/            # ~/.config/* templates
├── dot_dotfiles/          # ~/.dotfiles/* shell modules and helpers
│   ├── bash/              # bash init + late-init
│   ├── zsh/               # zsh rc, init, late-init (no duplicate bootstrap loading)
│   ├── common/            # aliases, functions, prompt (all roles)
│   ├── laptop/            # laptop-only SSH/server helpers
│   ├── container/         # k8s/terraform helpers (devops, local, remote roles)
│   ├── local/             # local devcontainer env defaults
│   ├── remote/            # remote devcontainer env defaults
│   ├── compiled/          # shell.tmpl → ~/.dotfiles/compiled/shell (generated)
│   └── fragments/         # optional, role-gated shell function files (source-only)
├── dot_local/             # ~/.local/* binaries and helpers
├── private_dot_ssh/       # ~/.ssh/* templates
├── dot_bashrc.tmpl        # ~/.bashrc
├── dot_zshrc.tmpl         # ~/.zshrc
└── ...
```

Repo root (never applied to `$HOME`): `.devcontainer/`, `tests/`, `docs/`, `bootstrap.sh`.

## The `role` vs `gui` distinction — never conflate these

Two independent axes describe a host:

- **Role**: what the machine *is*. One of `laptop`, `server`, `vm`, `devops`, `local`, `remote`.
  Controls role-specific shell helpers, SSH aliases, server packages, etc.
  - `devops` — legacy devcontainer role (still supported)
  - `local` — devcontainer on the laptop; remote Docker/Coolify/Dozzle via Tailscale + SSH
  - `remote` — devcontainer on the Coolify host; local Docker socket, Dozzle on localhost
- **GUI**: whether the machine has a graphical desktop. Boolean.
  Controls GUI packages, GUI helper scripts, Nautilus templates, autostart, etc.

**Rule:** a server can have `gui=true`; a laptop can have `gui=false`. Do not
use `.role == "laptop"` to mean "this host has a GUI". Gate GUI things on
`.gui` and only on `.gui`.

Host metadata lives in `home/.chezmoidata/hosts.toml` and is read by
`home/.chezmoi.toml.tmpl`. Unknown hostnames fall back to `role="server"`,
`gui=false`, `tags=[]` — the least-privileged, least-GUI default.

## Where configuration is declared

| Concern | File |
|---|---|
| Host → role/gui/tags | `home/.chezmoidata/hosts.toml` |
| Tools (mise) | `home/.chezmoidata/roles.toml` (`[tools.*]`) |
| Packages (apt) | `home/.chezmoidata/roles.toml` (`[packages.*]`) |
| Shell fragments | `home/.chezmoidata/fragments.toml` |
| Public SSH servers | `home/.chezmoidata/roles.toml` (`[servers]`) |
| Shared fragment loader | `home/.chezmoitemplates/load-fragments.tmpl` |
| GUI helper scripts | `home/dot_local/bin/gui/` |
| Per-role shell helpers | `home/dot_dotfiles/<role>/` |

## Core principles

1. Never store secrets directly in the repository.
2. Prefer templates over duplicated files.
3. Keep host-specific configuration minimal.
4. All changes must be safe to re-apply.
5. Production configuration must be conservative and security-focused.
6. Every new feature should work on at least `laptop` and `server`.
7. Never conflate `role` with `gui`.

## Secrets policy

Never commit passwords, private SSH keys, API keys, tokens, or certificates.
Use chezmoi's native secret support (`age`, `gpg`) or external secret managers.
Private SSH keys should be ignored or managed externally.

### 1Password CLI authentication

The age encryption key is retrieved from 1Password by
`home/.chezmoiscripts/run_once_before_02-setup-age-key.sh.tmpl`.
Three authentication methods are supported (tried in order):

1. **App Integration** (laptops/desktops) — the 1Password desktop app bridges
   to the CLI biometrically. No env vars needed. Enable in 1Password desktop
   app → Settings → Developer → "Integrate with 1Password CLI".
2. **Service Account** (dev containers / CI / headless) — set
   `OP_SERVICE_ACCOUNT_TOKEN` in `~/.dotfiles/dot_env/.env` (gitignored).
   Create a token at https://developer.1password.com/docs/service-accounts/.
3. **Interactive signin** — falls back to `op signin` for first-time desktop setup.

For dev containers, mount the 1Password socket from the host or use a Service
Account token. The token must have access to the vault containing the age key
item (`op://Security Keys/chezmoi age key/key.txt`).

### Age key for devcontainer roles

Devcontainers fetch the age key during primordial bootstrap:

- `.devcontainer/scripts/setup-age-key.sh` downloads `op://Security Keys/chezmoi age key/key.txt`
  to `~/.config/age/key.txt` after initial `op` authentication.
- `.devcontainer/scripts/decrypt-primordial-env.sh` decrypts the baked-in
  `.devcontainer/secrets/primordial.env.age` — the **first `.env`** for all primordial-based
  containers — into `/var/lib/primordial/primordial.env` and sources it.
- `home/.chezmoi.toml.tmpl` uses `identity = "~/.config/age/key.txt"` for all roles.
- `home/.chezmoiscripts/run_onchange_01-gen-env.sh.tmpl` decrypts repo `secrets/env.txt.age`
  into `~/.dotfiles/dot_env/.env` using the same key.

Initial `op` auth requires 1Password app integration or a host bootstrap token; after
primordial env decrypt, secrets from the age-encrypted file are available in the shell.

### DOTFILES_ROLE env var fallback

Unknown hostnames (e.g. devcontainers with random container IDs) fall back to
the `DOTFILES_ROLE` environment variable instead of defaulting to `server`:

```toml
{{- $role := dig $hostname "role" (env "DOTFILES_ROLE" | default "server") $hostsFile.hosts -}}
```

The devcontainer sets `DOTFILES_ROLE=local` (laptop) or `DOTFILES_ROLE=remote` (server)
in `remoteEnv` so chezmoi picks up the correct role without needing the hostname in
`hosts.toml`. Host entries `devops-local01` and `devops-remote01` in `hosts.toml`
provide the canonical hostname mapping when `DOTFILES_HOSTNAME` is set.

## Shell configuration

Primary shell: `bash`. Optional: `zsh`.

At `chezmoi apply`, all aliases, functions, role modules, and enabled fragments
are **compiled** into a single file: `~/.dotfiles/compiled/shell`. Both
`~/.bashrc` and `~/.zshrc` source this file first, then load prompt/tool init,
PATH, and late-init (zoxide) separately.

Runtime settings live in `~/.config/dotfiles/settings.yaml`. Set `VERBOSE: 1`
to print coloured logs (to stderr) listing each compiled module and whether
bootstrap came from `bashrc` or `zshrc`.

Source modules under `dot_dotfiles/` (common/, fragments/, laptop/, etc.) are
**not** applied individually — they are merged by
`.chezmoitemplates/compile-shell.tmpl`. Edit the source files in the repo;
re-run `chezmoi apply` to regenerate `compiled/shell`.

Changes to shell startup files must:

- remain POSIX compatible where possible
- avoid slowing login
- support non-interactive shells

Heavy tooling initialization (mise, zoxide, starship, fzf) is lazy-loaded and
checks for the tool before activating.

## Package and tool management

Ubuntu packages are installed by `home/.chezmoiscripts/run_once_before_01-install-packages.sh.tmpl`
and merged from `[packages.common]`, `[packages.<role>]`, and `[packages.gui]`
when the host has `gui=true`. Container roles (`devops`, `local`, `remote`) share
`[packages.container]` instead of duplicating identical lists.

Mise tools are declared in `[tools.common]`, `[tools.<role>]`, and `[tools.gui]`
and merged in `home/dot_config/mise/config.toml.tmpl`. Container roles share
`[tools.container]`.

## Development vs production

- **Laptop** may include Docker, Node.js, GUI apps, development SDKs, and desktop configuration.
- **Server** prioritizes security, stability, and a minimal footprint. Avoid GUI software.
- **VM** stays lightweight and disposable.
- **DevOps / devcontainer** — three roles share k8s/terraform helpers under
  `dot_dotfiles/container/` and Coolify management, but differ in environment defaults:
  - **`local`** (`devops-local01`) — devcontainer on the laptop; SSH keys bind-mounted,
    remote Docker context, Dozzle on the Coolify host via Tailscale.
  - **`remote`** (`devops-remote01`) — devcontainer on the Coolify host; local Docker
    socket, Dozzle on `127.0.0.1`, no SSH Docker context.
  - **`devops`** — legacy alias; same ephemeral age key behavior as `local`/`remote`.
  Mise installs kubectl, helm, k9s, terraform, and lazydocker for all three.
  The repo-local devcontainer (`.devcontainer/`) sets `DOTFILES_ROLE=local` by default;
  use `.devcontainer/devcontainer.remote.json` on the server.
  Published base images: `ghcr.io/saintgermainlabs/linux-mgmt-primordial:24.04` and
  `ghcr.io/saintgermainlabs/linux-mgmt-base:24.04` (see `.github/workflows/devcontainer-base.yml`).
  Secrets: `OP_SERVICE_ACCOUNT_TOKEN` and `TAILSCALE_AUTHKEY` via devcontainer secrets.
  Remote Docker inspection uses SSH-backed contexts (`docker_remote_use`), not TCP 2375.
SSH configuration is templated. Public servers may be listed in
`home/.chezmoidata/roles.toml`. Private servers must be supplied via local
chezmoi data or environment variables. Never deploy laptop-only SSH aliases
to production.

## Script naming standards

- One-time setup: `run_once_*`
- Re-run when modified: `run_onchange_*`
- Periodic maintenance: `scripts/`

All scripts must be idempotent, log meaningful output, and fail on errors.
Use `set -euo pipefail`.

## AI agent workflow

Before making changes:

1. Determine the target environment from `hosts.toml`.
2. Determine whether a template already exists.
3. Prefer modifying templates over adding duplicates.
4. Verify no secrets are introduced.
5. Ensure changes are safe on repeated applies.

When adding new configuration, ask:

- Is this gated by `role`, by `gui`, or by both?
- Is this laptop-only?
- Is this production-only?
- Should VMs inherit this?

## Testing procedure

Before committing:

```bash
chezmoi diff
chezmoi apply --dry-run
chezmoi apply
```

Validate:

```bash
chezmoi doctor
```

For every hostname in `home/.chezmoidata/hosts.toml` (plus an unknown host),
verify that `home/.chezmoi.toml.tmpl` and `home/.chezmoiignore.tmpl` render
correctly and that GUI-only paths are excluded exactly when `gui=false`.

## Definition of done

A change is complete when:

- templates render correctly for every host
- no secrets are committed
- `chezmoi apply` succeeds
- repeated applies are safe
- laptop and production behavior are verified
- this file is updated if required
