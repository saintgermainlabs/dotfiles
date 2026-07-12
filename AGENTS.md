# AGENTS.md

This repository manages personal and server configuration using Chezmoi and Mise.
Every change must be safe to re-apply with `chezmoi apply`.

## Repository layout

`.chezmoiroot` points Chezmoi at the `home/` subdirectory. Files outside `home/`
(README, bootstrap, docs, this file, etc.) live only in the source repo and are
never applied to `$HOME`.

```text
home/
├── .chezmoidata/          # host, role, tool, package, fragment, server data
├── .chezmoiscripts/       # run_once_* / run_onchange_* scripts
├── .chezmoitemplates/     # reusable template fragments
├── dot_config/            # ~/.config/* templates
├── dot_dotfiles/          # ~/.dotfiles/* shell modules and helpers
├── dot_local/             # ~/.local/* binaries and helpers
├── private_dot_ssh/       # ~/.ssh/* templates
├── dot_bashrc.tmpl        # ~/.bashrc
├── dot_zshrc.tmpl         # ~/.zshrc
└── ...
```

## The `role` vs `gui` distinction — never conflate these

Two independent axes describe a host:

- **Role**: what the machine *is*. One of `laptop`, `server`, `vm`, `devops`.
  Controls role-specific shell helpers, SSH aliases, server packages, etc.
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
6. Every new feature should work on at least `laptop`, `server`, and `devops`.
7. Never conflate `role` with `gui`.

## Secrets policy

Never commit passwords, private SSH keys, API keys, tokens, or certificates.
Use chezmoi's native secret support (`age`, `gpg`) or external secret managers.
Private SSH keys should be ignored or managed externally.

## Shell configuration

Primary shell: `bash`. Optional: `zsh`.

Changes to shell startup files must:

- remain POSIX compatible where possible
- avoid slowing login
- support non-interactive shells

Heavy tooling initialization (mise, zoxide, starship, fzf) is lazy-loaded and
checks for the tool before activating.

## Package and tool management

Ubuntu packages are installed by `home/.chezmoiscripts/run_once_before_01-install-packages.sh.tmpl`
and merged from `[packages.common]`, `[packages.<role>]`, and `[packages.gui]`
when the host has `gui=true`.

Mise tools are declared in `[tools.common]`, `[tools.<role>]`, and `[tools.gui]`
and merged in `home/dot_config/mise/config.toml.tmpl`.

## Development vs production

- **Laptop** may include Docker, Node.js, GUI apps, development SDKs, and desktop configuration.
- **Server** prioritizes security, stability, and a minimal footprint. Avoid GUI software.
- **VM** stays lightweight and disposable.
- **DevOps** is a dev container role with all common fragments, Docker, Kubernetes
  (kubectl, helm, k9s), Terraform, and Coolify management tools. Designed for
  containerized CI/CD and infrastructure-as-code workflows.

## SSH standards

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
