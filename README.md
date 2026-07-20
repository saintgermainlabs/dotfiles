# dotfiles

Personal dotfiles for Ubuntu hosts, managed with [Chezmoi](https://www.chezmoi.io/) and [Mise](https://mise.jdx.dev/).

## Supported roles

|Role|Use case|Notes|
|---|---|---|
|`laptop`|Ubuntu desktop/workstation|GUI tools, Nautilus templates, desktop helper scripts|
|`server`|Hetzner/VPS production|Minimal CLI footprint, Docker/server aliases|
|`vm`|Ephemeral dev/test VM|Lightweight, disposable|
|`devops`|VS Code devcontainer (legacy)|Same as `local`/`remote`; prefer those for new setups|
|`local`|Devcontainer on laptop|Remote Docker/Coolify/Dozzle via Tailscale + SSH|
|`remote`|Devcontainer on Coolify host|Local Docker socket, Dozzle on localhost|

## Devcontainer

Open this repo in a devcontainer for a pre-configured Coolify debugging environment.

Two devcontainer profiles are available:

| Profile | Config | Role | Use when |
|---|---|---|---|
| **Default** | `.devcontainer/devcontainer.json` | from `.devcontainer/profile` | Works on laptop and server |
| **Local** | `.devcontainer/devcontainer.local.json` | `local` | Laptop + 1Password app integration + SSH agent |
| **Remote** | `.devcontainer/devcontainer.remote.json` | `remote` | Coolify host + service account token |

Set the profile explicitly on each machine (recommended):

```bash
cp .devcontainer/profile.example .devcontainer/profile
# laptop:  echo local  > .devcontainer/profile
# server:   echo remote > .devcontainer/profile
```

`resolve-profile.sh` runs in `initializeCommand` before the container starts, writes
`.devcontainer/.profile.runtime`, and sets `DOTFILES_ROLE` / `DOTFILES_HOSTNAME` for
chezmoi. If `.devcontainer/profile` is missing, it auto-detects `ubuntu-24` /
`ubuntu-server` as **remote** and a present `~/.1password/agent.sock` as **local**.

You can still pick a devcontainer JSON manually, but the profile file wins over
hardcoded defaults when both are present.

### Image layout

Devcontainers use a multi-stage Dockerfile at [`.devcontainer/docker/Dockerfile`](.devcontainer/docker/Dockerfile):

| Stage | Purpose |
|---|---|
| `primordial` | Foundation: essential apt packages, bootstrap scripts, `op` CLI, build-time env probe |
| `base` | Devcontainer runtime: vscode user, Tailscale state dirs |
| `dotfiles` | Dotfiles profile: uv, aider, extra Python tooling |

Build the primordial stage alone (reusable across devops/dotfiles variants):

```bash
docker build -f .devcontainer/docker/Dockerfile --target primordial \
  -t linux-mgmt-primordial:24.04 .devcontainer
```

Build the base stage:

```bash
docker build -f .devcontainer/docker/Dockerfile --target base \
  -t linux-mgmt-base:24.04 .devcontainer
```

### Published images (GHCR)

On push to `main`/`master`, GitHub Actions publishes:

| Image | Stage | Use |
|---|---|---|
| `ghcr.io/saintgermainlabs/linux-mgmt-primordial:24.04` | `primordial` | Shared foundation for custom devcontainers |
| `ghcr.io/saintgermainlabs/linux-mgmt-base:24.04` | `base` | Primordial + vscode user + mount paths |
| `ghcr.io/saintgermainlabs/linux-mgmt-dotfiles:24.04` | `dotfiles` | Base + python/uv/aider dotfiles provisioner layer |

Tags also include `:latest` and the commit SHA. Pull (private packages require `gh auth login`):

```bash
docker pull ghcr.io/saintgermainlabs/linux-mgmt-primordial:24.04
docker pull ghcr.io/saintgermainlabs/linux-mgmt-dotfiles:24.04
```

Child Dockerfiles can extend the published image instead of rebuilding locally:

```dockerfile
FROM ghcr.io/saintgermainlabs/linux-mgmt-dotfiles:24.04 AS devops
# devops-specific layers...
```

Or from base:

```dockerfile
FROM ghcr.io/saintgermainlabs/linux-mgmt-base:24.04 AS dotfiles
# role-specific layers...
```

Workflow: [`.github/workflows/devcontainer-base.yml`](.github/workflows/devcontainer-base.yml)

### Primordial encrypted env (first `.env`)

The primordial image ships with an **age-encrypted** env file baked in at build time
(ciphertext only — never decrypted during `docker build`).

| File | Purpose |
|---|---|
| `.devcontainer/secrets/primordial.env.example` | Template (committed) |
| `.devcontainer/secrets/primordial.env` | Plaintext secrets (gitignored) |
| `.devcontainer/secrets/primordial.env.age` | Encrypted env baked into image (committed) |

**Create and publish:**

```bash
cp .devcontainer/secrets/primordial.env.example .devcontainer/secrets/primordial.env
$EDITOR .devcontainer/secrets/primordial.env
.devcontainer/scripts/encrypt-primordial-env.sh
git add .devcontainer/secrets/primordial.env.age
git commit -m "Update primordial encrypted env"
git push   # GHCR rebuild picks up the new ciphertext
```

**At container bootstrap** (not image build):

1. `authenticate-op` — 1Password app integration or host `.env.runtime` bootstrap token
2. `setup-age-key` — fetch age key from 1Password
3. `decrypt-primordial-env` — decrypt `/opt/primordial/secrets/primordial.env.age` → `/var/lib/primordial/primordial.env` and source it

After step 3, variables like `OP_SERVICE_ACCOUNT_TOKEN`, `TAILSCALE_AUTHKEY`, and API keys
from the encrypted file are exported for the rest of bootstrap.

Decrypting during `docker build` would bake secrets into image layers — do not do that
for published GHCR images.

### Host `.env` (optional bootstrap)

[`.devcontainer/.env`](.devcontainer/.env) with `op://` refs is still used on the **host**
for `initializeCommand` and image tests when 1Password app integration is unavailable.
Once primordial bootstrap runs inside the container, the decrypted primordial env takes over.

### Local devcontainer — 1Password app integration

The **local** profile (`devcontainer.json`) uses the 1Password **desktop app** on your
laptop — no `OP_SERVICE_ACCOUNT_TOKEN` required.

**One-time host setup:**

1. Install [1Password for Linux](https://1password.com/downloads/linux)
2. Unlock the app
3. **Settings → Developer →** enable **Integrate with 1Password CLI**
4. Verify on the host:

```bash
op whoami
bash .devcontainer/scripts/check-1password-app.sh
```

**Optional** — resolve Tailscale/Dozzle refs at container start:

```bash
cp .devcontainer/.env.example .devcontainer/.env
$EDITOR .devcontainer/.env   # op:// refs only; no service account token
```

**Open devcontainer:**

Command Palette → **Dev Containers: Rebuild Container** (no secrets prompt for OP token)

The local config bind-mounts `~/.1password/agent.sock` into the container so `op` inside
the devcontainer uses your desktop app session.

### Remote devcontainer — service account token

The **remote** profile (`devcontainer.remote.json`) requires `OP_SERVICE_ACCOUNT_TOKEN`
(headless server — no desktop app). See prerequisites below.

### Image integration tests

Secrets are supplied at **container runtime** via [`.devcontainer/.env`](.devcontainer/.env)
(never Dockerfile ARG — that would leak into image layers).

**Setup:**

```bash
cp .devcontainer/.env.example .devcontainer/.env
$EDITOR .devcontainer/.env   # set op:// refs for your vault items
```

**Run tests against a pulled GHCR image:**

```bash
.devcontainer/scripts/run-image-tests.sh
```

`load-op-env.sh` reads `.devcontainer/.env`, resolves `op://` refs with `op read` on the
host (1Password desktop integration), and writes `.devcontainer/.env.runtime` for
`docker run --env-file`.

**Devcontainer (local):** app integration via mounted `~/.1password` socket.

**Devcontainer (remote):** `initializeCommand` loads `.devcontainer/.env` and requires
`OP_SERVICE_ACCOUNT_TOKEN`.

**CI:** use GitHub repository secrets instead of `.env`; pass with `docker run -e`.

Bootstrap scripts live in [`.devcontainer/scripts/`](.devcontainer/scripts/):

| Script | When | Purpose |
|---|---|---|
| `install-op-cli.sh` | Build + runtime | Install `op` if missing |
| `probe-env.sh` | Build + runtime | Write environment facts to `/var/lib/primordial/*.json` |
| `load-op-env.sh` | Host / tests / devcontainer init | Load `.devcontainer/.env`, resolve op:// refs, write `.env.runtime` |
| `load-op-token.sh` | Host | Wrapper for `load-op-env.sh` |
| `authenticate-op.sh` | Runtime (post-create) | Verify `OP_SERVICE_ACCOUNT_TOKEN` / `op whoami` |
| `setup-age-key.sh` | Runtime (post-create) | Fetch `~/.config/age/key.txt` from 1Password for decryption |
| `encrypt-env.sh` | Host / devcontainer | Encrypt fed env vars into `secrets/env.txt.age` |
| `decrypt-env.sh` | Runtime (post-create) | Decrypt `secrets/env.txt.age` → `~/.dotfiles/dot_env/.env` |
| `bootstrap-primordial.sh` | Runtime (post-create) | Orchestrates mount verify, auth, age key, decrypt env, probe |
| `check-1password-app.sh` | Host (local) | Verify desktop app integration before rebuild |

| `verify-mounts.sh` | Runtime (post-create) | Verify ~/.ssh, 1Password socket, volumes; write `mounts.json` |

The `op` CLI and `age` are installed in the primordial image at build time.
Local devcontainers authenticate via app integration; remote uses a service account token.

### Encrypted environment file

Store machine-local secrets in an age-encrypted file committed to the repo:

```bash
# From explicit values
export COOLIFY_API_TOKEN="..."
export GEMINI_API_KEY="..."
.devcontainer/scripts/encrypt-env.sh COOLIFY_API_TOKEN GEMINI_API_KEY

# Or from a plaintext file (gitignored)
cp secrets/env.txt.example secrets/env.txt
$EDITOR secrets/env.txt
.devcontainer/scripts/encrypt-env.sh -f secrets/env.txt -o secrets/env.txt.age
```

On devcontainer create (or `chezmoi apply`), `decrypt-env.sh` / `gen-env` writes
`~/.dotfiles/dot_env/.env` using the age key from primordial bootstrap.

Plaintext `secrets/env.txt` is gitignored; `secrets/env.txt.age` is safe to commit.

### Shared mounts

All profiles inherit mounts from [`.devcontainer/devcontainer.base.json`](.devcontainer/devcontainer.base.json):

| Mount | Target | Type | Purpose |
|---|---|---|---|
| Host `~/.ssh` | `/home/vscode/.ssh` | bind (readonly) | SSH keys for remote servers and Docker contexts |
| `devcontainer-primordial-state` | `/var/lib/primordial` | volume | Persist primordial probe/bootstrap state across rebuilds |

Each profile adds its own Tailscale state volume (`devcontainer-tailscale-state` or
`-remote`). At post-create, `verify-mounts.sh` checks these paths and writes
`/var/lib/primordial/mounts.json`.

### Prerequisites

1. **1Password** — local: desktop app integration; remote: service account with access to:
   - `op://Security Keys/chezmoi age key/key.txt`
   - `op://SG-Labs/Coolify API/token`
   - (Optional) `op://SG-Labs/Dozzle/*` for Dozzle basic auth
2. **Tailscale auth key** for the devcontainer node (optional at rebuild; can use ref in `.env`)
3. **SSH keys** on the host at `~/.ssh/` (bind-mounted read-only into the container)

### Setup (local)

1. Run `bash .devcontainer/scripts/check-1password-app.sh` on the host
2. Command Palette → **Dev Containers: Rebuild Container**
3. On first create, `post-create.sh` bootstraps primordial env and runs `chezmoi apply`

### Setup (remote)

1. Command Palette → **Dev Containers: Rebuild Container and Reopen With Secrets**
2. Provide `OP_SERVICE_ACCOUNT_TOKEN` and `TAILSCALE_AUTHKEY`
4. On each start, `post-start.sh` connects Tailscale and optionally configures
   a remote Docker context when `COOLIFY_DOCKER_HOST` is set.

### Verify

```bash
bash .devcontainer/scripts/check_health.sh
coolify_diag && coolify_health
tailscale status
dozzle_containers    # requires DOZZLE_HOST/DOZZLE_PORT in ~/.dotfiles/dot_env/.env
docker_remote_use root@ubuntu-24.tiger-bushmaster.ts.net && docker ps
```

**Note:** Devcontainers pull from the remote on rebuild. Commit and push changes
before rebuilding on another machine.

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
