# Structuring a Multi-Host Dotfiles Project with Chezmoi + Mise

## The core idea

You have one source-of-truth repo. Chezmoi decides *what* gets written to disk on
a given machine (using templates + data variables). Mise decides *which tool
versions* are available on a given machine, driven by a config file that
chezmoi itself templates out. The two layers work together:

- **Chezmoi** = files, symlinks, scripts, conditionals ("does this host get a
  GNOME config? a Nautilus template? a `.bashrc` vs `.zshrc`?")
- **Mise** = toolchains ("this host gets Node 22 + Go 1.23; that server only
  gets Go 1.23")

The trick that makes this scale to three (and eventually N) host types is
giving every host a **role**, stored as chezmoi template data, and letting
everything else — files, mise config, packages — branch off that one variable.

---

## 1. Define your roles up front

Pick a small, closed set of roles rather than branching on hostname or OS
everywhere. Something like:

| Role       | Example host              | GUI? | Notes |
|------------|---------------------------|------|-------|
| `laptop`   | your Ubuntu laptop        | yes  | Nautilus templates, GTK stuff, fonts, desktop apps |
| `server`   | Hetzner VPS               | no   | Minimal shell, CLI tools only |
| `vm`       | Multipass/Vagrant guest   | no   | Same as server, possibly ephemeral so must bootstrap fast |

You'll store this as a single `role` variable in chezmoi's data, and a
secondary `gui` boolean derived from it (or just check `role == "laptop"`
directly — either works, `gui` reads a bit nicer in templates).

---

## 2. Repo layout

```
dotfiles/
├── .chezmoi.toml.tmpl          # prompts/sets role on `chezmoi init`
├── .chezmoidata/
│   └── roles.toml              # static data: which packages/tools per role
├── .chezmoiexternal.toml       # optional: pull in oh-my-zsh, plugins, etc.
├── .chezmoiignore.tmpl         # exclude files per role (e.g. skip GUI configs on servers)
├── .chezmoiroot                # optional, if you nest the actual source under home/
├── .chezmoiscripts/             # (or just run_ prefixed files anywhere in source)
│   ├── run_once_before_00-install-mise.sh.tmpl
│   ├── run_once_before_01-install-packages.sh.tmpl
│   ├── run_onchange_after_10-mise-install-tools.sh.tmpl
│   └── run_once_after_20-gui-setup.sh.tmpl
├── dot_config/
│   ├── mise/
│   │   └── config.toml.tmpl     # templated per-role tool list
│   ├── nvim/...
│   └── ...
├── dot_bashrc.tmpl
├── dot_zshrc.tmpl
├── dot_gitconfig.tmpl
├── private_dot_ssh/
│   └── config.tmpl
└── templates/
    ├── nautilus-templates.tmpl  # only materialized for laptop role, see below
    └── partials/...
```

Key chezmoi conventions used above:
- `dot_` → becomes `.` in `$HOME` (e.g. `dot_bashrc` → `~/.bashrc`)
- `private_` → file gets `0600` perms (good for `.ssh/config`, secrets)
- `run_once_`, `run_onchange_`, `_before`/`_after` → scripts that execute at
  specific points in `chezmoi apply`, only when needed
- `.tmpl` suffix → file goes through Go templating before being written

---

## 3. Setting the role: `.chezmoi.toml.tmpl`

This file is itself a template, evaluated once on `chezmoi init`, and prompts
you (or auto-detects) the role. This is the one bit of manual input per host.

```toml
{{- $role := "" -}}
{{- if env "DOTFILES_ROLE" -}}
  {{- $role = env "DOTFILES_ROLE" -}}
{{- else if eq .chezmoi.hostname "your-laptop-hostname" -}}
  {{- $role = "laptop" -}}
{{- else -}}
  {{- $role = promptStringOnce . "role" "Host role (laptop/server/vm)" "server" -}}
{{- end -}}

[data]
    role = {{ $role | quote }}
    gui  = {{ eq $role "laptop" }}
```

This gives you three ways to set role, in priority order:
1. Environment variable (`DOTFILES_ROLE=vm chezmoi init ...`) — perfect for
   scripted Multipass/Vagrant provisioning where there's no interactive prompt.
2. Hostname match — your laptop always self-identifies correctly.
3. Interactive prompt — fallback for anything new, asked once and cached in
   `~/.config/chezmoi/chezmoi.toml`.

---

## 4. Branching files by role

### Skipping whole files/dirs: `.chezmoiignore.tmpl`

```
{{- if ne .role "laptop" }}
.config/nautilus/
.config/gtk-3.0/
.config/autostart/
Templates/
.local/share/applications/
{{- end }}
```

Anything listed here simply won't be created on non-laptop hosts, no `if`
statements needed inside those files.

### Nautilus templates (laptop-only)

Put your actual template files under a source path that only gets processed
for the laptop role, e.g. `Templates/empty.md`, `Templates/script.sh`, etc.
Since `.chezmoiignore` already excludes `Templates/` for non-laptop roles,
you don't need per-file conditionals — just author them normally:

```
dotfiles/
└── Templates/
    ├── New Document.md
    ├── New Shell Script.sh
    └── New Python Script.py
```

chezmoi will create `~/Templates/*` verbatim on the laptop and skip the
directory entirely elsewhere.

### Conditionals inside a shared file

For files that exist everywhere but differ slightly (e.g. `.bashrc`):

```bash
# dot_bashrc.tmpl
export EDITOR=nvim

{{- if .gui }}
# Laptop-only: GUI clipboard integration, etc.
alias pbcopy='xclip -selection clipboard'
{{- end }}

{{- if eq .role "server" }}
# Server-only: tighter history, no motd spam
export HISTCONTROL=ignoreboth
{{- end }}
```

---

## 5. Mise integration

Mise reads `~/.config/mise/config.toml` (or a project-local `.mise.toml`).
Template that file the same way, driven by `.chezmoidata/roles.toml`:

```toml
# .chezmoidata/roles.toml
[tools.common]
"go" = "1.23"
"ripgrep" = "latest"
"fzf" = "latest"

[tools.laptop]
"node" = "22"
"python" = "3.12"
"terraform" = "latest"

[tools.server]
"node" = "22"          # e.g. for a small app you run there

[tools.vm]
"node" = "22"
```

```toml
# dot_config/mise/config.toml.tmpl
[tools]
{{- range $tool, $version := .tools.common }}
{{ $tool }} = {{ $version | quote }}
{{- end }}
{{- $roleTools := index .tools .role }}
{{- range $tool, $version := $roleTools }}
{{ $tool }} = {{ $version | quote }}
{{- end }}

[settings]
experimental = true
```

Then a `run_onchange_` script installs whatever the rendered config
specifies, and — importantly — only re-runs when the *rendered content*
changes (chezmoi hashes the script body including templated output, so
editing `roles.toml` triggers a re-run automatically):

```bash
#!/bin/bash
# run_onchange_after_10-mise-install-tools.sh.tmpl
# hash of config to force rerun on change: {{ include "dot_config/mise/config.toml.tmpl" | sha256sum }}
set -euo pipefail
mise install
mise prune -y
```

---

## 6. Bootstrap script (installing chezmoi + mise themselves)

For a brand-new host — especially ephemeral ones like Vagrant/Multipass VMs
— you want a one-liner that installs chezmoi, installs mise, and applies the
dotfiles, before chezmoi's own scripts can even run:

```bash
#!/bin/sh
# bootstrap.sh — the one thing you run manually or via `vagrant provision`
set -eu

# mise (also gives you a shim for any tool version pinning immediately)
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GH_USERNAME
```

For scripted VM provisioning, pass the role via env var so there's no
interactive prompt:

```bash
DOTFILES_ROLE=vm sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GH_USERNAME
```

Vagrant example (`Vagrantfile`):

```ruby
config.vm.provision "shell", inline: <<-SHELL
  su - vagrant -c "DOTFILES_ROLE=vm sh -c \\"$(curl -fsLS get.chezmoi.io)\\" -- init --apply YOUR_GH_USERNAME"
SHELL
```

Multipass example:

```bash
multipass launch --name devbox --cloud-init cloud-init.yaml
# in cloud-init.yaml runcmd:
runcmd:
  - su - ubuntu -c 'DOTFILES_ROLE=vm sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GH_USERNAME'
```

---

## 7. Package installation, still branched by role

Similar pattern for apt packages — keep the list as data, not logic:

```toml
# add to .chezmoidata/roles.toml
[packages.common]
list = ["git", "curl", "build-essential", "tmux"]

[packages.laptop]
list = ["nautilus", "gnome-tweaks", "flameshot"]

[packages.server]
list = ["ufw", "fail2ban"]

[packages.vm]
list = []
```

```bash
#!/bin/bash
# run_once_before_01-install-packages.sh.tmpl
set -euo pipefail
sudo apt-get update
sudo apt-get install -y \
{{- range .packages.common.list }} {{ . }}{{ end }}
{{- $roleList := index .packages .role }}
{{- range $roleList.list }} {{ . }}{{ end }}
```

---

## 8. Adding a fourth host type later

Because everything branches off `.role`, adding e.g. `role = "container"` or
`role = "wsl"` later means:
1. Add an entry to `.chezmoidata/roles.toml` (`[tools.container]`,
   `[packages.container]`).
2. Optionally add a case in `.chezmoiignore.tmpl` if it needs different
   exclusions than `server`.
3. Nothing else changes — no restructuring of the repo.

---

## 9. Day-to-day workflow

```bash
# On any host, after initial setup:
chezmoi edit ~/.bashrc          # opens the source file, not the target
chezmoi diff                    # preview what would change
chezmoi apply                   # apply changes
chezmoi update                  # git pull + apply, for pulling changes made elsewhere

# Re-check role assigned to this host:
chezmoi data | grep role
```

Commit early and often — the `.chezmoidata/roles.toml` file effectively
becomes your inventory of "what exists on which kind of machine," which is
useful documentation on its own even before you look at any code.

---

## Summary of responsibilities

| Concern | Owned by |
|---|---|
| Which files exist on a host | `.chezmoiignore.tmpl` + directory structure |
| Content differences within a shared file | `{{ if }}` blocks using `.role`/`.gui` |
| Which CLI tool versions are installed | mise, config templated from `.chezmoidata/roles.toml` |
| Which apt packages are installed | `run_once_before` script + same data file |
| Initial provisioning on a new/ephemeral host | `bootstrap.sh` + `DOTFILES_ROLE` env var |
| "What is this host, structurally" | The single `role` variable — everything reads from it |
