# Dotfiles Repo Remediation Plan

Goal: eliminate the `role`/`gui` conflation (the root cause of the "desktop" mess),
consolidate stray/dead paths, and add guardrails so an agent (Devin or otherwise)
can't reintroduce the same class of bug.

Work in the order below — each phase depends on the previous one being in place.

---

## Phase 0 — Safety net before touching anything

- [ ] Create a branch: `git checkout -b fix/role-gui-split`
- [ ] Confirm `chezmoi doctor` is clean on at least one real host before starting
- [ ] Note current `chezmoi state` is untouched — no manual `state delete-bucket` needed
  for this migration; changed template output naturally re-triggers `run_once_`/`run_onchange_`
  scripts via their content hash

---

## Phase 1 — Data model: split `role` from `gui`

**Why first:** everything else (ignore rules, fragments, package/tool merges, scripts)
reads `.role` and `.gui` from this layer. Get this right and every downstream file
becomes a mechanical find-and-fix.

### 1.1 `home/.chezmoidata/hosts.toml` (new or rename from existing `hosts.yaml`)

```toml
[hosts."ubuntu-laptop"]
role = "laptop"
gui  = true
tags = ["personal", "primary"]

[hosts."ubuntu-24"]
role = "server"
gui  = false
tags = ["homelab", "coolify-host"]

[hosts."vm-dev01"]
role = "vm"
gui  = false
tags = ["ephemeral"]
```

Add every real host you currently manage. Anything not listed falls back to
`role="server", gui=false` (see 1.2) — the least-privileged, least-GUI default.

### 1.2 `home/.chezmoi.toml.tmpl`

```toml
{{- $role := dig .chezmoi.hostname "role" "server" .hosts -}}
{{- $gui  := dig .chezmoi.hostname "gui"  false    .hosts -}}
{{- $tags := dig .chezmoi.hostname "tags" list     .hosts -}}

[data]
    role     = {{ $role | quote }}
    # unrecognized hostnames fall back to "server"/gui=false —
    # the least-privileged, least-GUI configuration. Do not invert this default.
    gui      = {{ $gui }}
    tags     = {{ $tags | toJson }}
    hostname = {{ .chezmoi.hostname | quote }}

    github_user = "saintgermainlabs"
    git_name    = "Saint Germain Labs"
    git_email   = "you@example.com"  # TODO: fill in real value

[diff]
    command = "diff"
    args    = ["-u"]
```

**Verify immediately, before moving on:**

```bash
chezmoi execute-template --init --promptString hostname=ubuntu-laptop < home/.chezmoi.toml.tmpl
chezmoi execute-template --init --promptString hostname=ubuntu-24     < home/.chezmoi.toml.tmpl
chezmoi execute-template --init --promptString hostname=some-unknown  < home/.chezmoi.toml.tmpl
```

Confirm the unknown-host case cleanly prints `role="server"`, `gui=false`, `tags=[]` —
no `<no value>`, no error.

### 1.3 `home/.chezmoidata/roles.toml`

Split every GUI-flavored entry out of role sections into a new `gui` section:

```toml
[tools.common]
"go" = "1.23"
"node" = "22"
"python" = "3.12"
"ripgrep" = "latest"
"fzf" = "latest"
"eza" = "latest"
"bat" = "latest"
"zoxide" = "latest"
"fd" = "latest"

[tools.laptop]
"terraform" = "latest"
"terraform-ls" = "latest"
"lazygit" = "latest"
"lazydocker" = "latest"
"starship" = "latest"

[tools.server]
"lazygit" = "latest"
"starship" = "latest"

[tools.vm]
"lazygit" = "latest"

[tools.gui]
# GUI-only tools go here (currently none)

[packages.common]
list = ["git","curl","build-essential","tmux","htop","btop","ripgrep","fd-find","eza","bat","fzf","zoxide","gettext-base"]

[packages.laptop]
list = []   # role-specific, non-GUI packages only

[packages.server]
list = ["ufw","fail2ban","rsync","vault"]

[packages.vm]
list = ["rsync"]

[packages.gui]
list = ["nautilus","nautilus-image-converter","wl-clipboard","zenity"]

[servers]
public = [
  { name = "github", ip = "github.com", user = "git", identity_file = "~/.ssh/id_ed25519_dev" },
  { name = "gitlab", ip = "gitlab.com", user = "git", identity_file = "~/.ssh/id_ed25519_dev" },
]
```

### 1.4 `home/.chezmoidata/fragments.toml`

Extend the valid-context vocabulary to include `"gui"`, keep the fragment→contexts shape:

```toml
# Valid contexts: "laptop", "server", "vm", "gui"
# ("gui" is a machine attribute, not a role — combines with any role)
[fragments]
docker_functions = ["laptop", "server"]
# terraform_functions = ["laptop"]
# k8s_functions = ["server"]
# zsh_completions = ["gui"]
```

---

## Phase 2 — Rename the physical `desktop` paths to `gui`

- [ ] `git mv home/dot_local/bin/desktop home/dot_local/bin/gui`
- [ ] Rename any `executable_*-gui` scripts inside if they still say `desktop-*`
- [ ] Search the whole repo for the literal string `desktop` and fix every remaining reference:
  ```bash
  grep -rn "desktop" home/ --include="*.tmpl" --include="*.sh"
  ```
  Expect hits in: `.chezmoiignore.tmpl`, `run_once_after_20-gui-setup.sh.tmpl`,
  possibly `dot_config/dotfiles/role-aliases.tmpl` (not yet reviewed — check it)

---

## Phase 3 — Fix consumers, in this order

### 3.1 `home/.chezmoiignore.tmpl`

```
# Chezmoi source files that should never be applied to $HOME.
/.chezmoi.toml.tmpl
/.chezmoidata/
/.chezmoiignore.tmpl
/.chezmoiscripts/

# Repo metadata / bootstrap files that live only in the source repo.
/AGENTS.md
/README.md
/bootstrap.sh
/dotfiles-chezmoi-mise-guide.md
/.gitignore

# GUI-conditional target paths (gated on .gui, not .role).
{{- if not .gui }}
.local/bin/gui/
.config/autostart/
Templates/
{{- end }}

# Role-conditional target paths.
{{- if ne .role "laptop" }}
.local/bin/laptop/
{{- end }}

{{- if ne .role "server" }}
.local/bin/server/
{{- end }}

{{- if ne .role "vm" }}
.local/bin/vm/
{{- end }}

# Role-specific scripts (keyed on .role, not hostname).
{{- if ne .role "laptop" }}
.chezmoiscripts/laptop
{{- end }}

# Git directory placeholders.
.gitkeep

# macOS / editor metadata.
.DS_Store
```

### 3.2 `home/.chezmoiscripts/.../run_once_before_01-install-packages.sh.tmpl`

Add the `.gui` package merge (see full script from prior review):

```bash
PACKAGES=(
{{- range .packages.common.list }}
  {{ . | quote }}
{{- end }}
{{- $roleList := index .packages .role }}
{{- range $roleList.list }}
  {{ . | quote }}
{{- end }}
{{- if .gui }}
{{- range .packages.gui.list }}
  {{ . | quote }}
{{- end }}
{{- end }}
)
```

### 3.3 `home/.chezmoiscripts/.../run_once_after_20-gui-setup.sh.tmpl`

```bash
#!/bin/bash
# GUI-only setup: create Nautilus templates and ensure GUI helper scripts are executable.
set -euo pipefail

{{ if not .gui }}
exit 0
{{ end }}

echo "Setting up GUI extras..."
mkdir -p "$HOME/Templates"
mkdir -p "$HOME/.local/bin/gui"
for script in "$HOME/.local/bin/gui/"*; do
  [ -f "$script" ] && chmod +x "$script"
done
echo "GUI setup complete."
```

### 3.4 mise config consumer (`dot_config/mise/config.toml.tmpl`)

Add the same `.gui` merge for tools:

```
{{- $tools := merge .tools.common (index .tools .role) -}}
{{- if .gui }}{{ $tools = merge $tools .tools.gui }}{{ end -}}
```

`run_onchange_after_10-mise-install-tools.sh.tmpl` needs **no changes** — it already
depends on the rendered config hash, so it re-runs automatically once the above changes.

### 3.5 `dot_bashrc.tmpl` / `dot_zshrc.tmpl` — shared fragment loader

Create `home/.chezmoitemplates/load-fragments.tmpl`:

```
{{- range $name, $contexts := .fragments -}}
{{-   $enabled := false -}}
{{-   range $contexts -}}
{{-     if or (eq . $.role) (and (eq . "gui") $.gui) -}}
{{-       $enabled = true -}}
{{-     end -}}
{{-   end -}}
{{-   if $enabled }}
source ~/.dotfiles/fragments/{{ $name }}
{{-   end -}}
{{- end -}}
```

In both `dot_bashrc.tmpl` and `dot_zshrc.tmpl`, replace any existing per-role
fragment logic with:

```
{{ template "load-fragments.tmpl" . }}
```

### 3.6 Check remaining unreviewed files

- [ ] `dot_config/dotfiles/role-aliases.tmpl` — likely references role/desktop; audit and fix
- [ ] `private_dot_ssh/config.tmpl` — confirm it's laptop-only via `.role`, not hostname
- [ ] `home/.chezmoiscripts/laptop/` contents — confirm nothing inside still branches on gui-ish logic that should just live outside the laptop-only dir

---

## Phase 4 — Delete / relocate dead weight

- [ ] Delete `deprecated_encryption/` entirely, after confirming nothing in
      `run_once_before_install-age-key.sh.tmpl` is still load-bearing (the only
      thing that might still be needed is the one-time age-key bootstrap for the
      1Password service-account token itself — migrate that specific piece into
      `home/.chezmoiscripts/` if so, everything else should already be superseded
      by `onepasswordRead`)
- [ ] Move `future_plans/` out of the repo, or into `docs/planning/` (it's already
      outside `.chezmoiroot` so this is pure hygiene, not a functional fix)
- [ ] Check `future_plans/test-secret.txt` isn't a real leaked value before it
      sits in git history further — if it is, treat as a rotation event
- [ ] Fold `dotfiles-chezmoi-mise-guide.md` into `docs/`, keep `README.md` as the
      single human-facing entry point
- [ ] Rewrite `AGENTS.md` to explicitly state: the `.chezmoiroot` layout, the
      `role` vs `gui` distinction (with a one-line "never conflate these again"),
      and where fragments/tools/packages are declared. This is the single highest-leverage
      fix against a repeat of this exact mess.

---

## Phase 5 — Guardrails so this doesn't happen again

- [ ] Add `.chezmoiversion` at repo root pinning a minimum chezmoi version
- [ ] Add a root `.mise.toml` pinning `shellcheck`/`shfmt`, so template scripts
      get linted consistently regardless of who/what edits them
- [ ] Add CI (GitHub Actions) that runs, for every hostname in `hosts.toml`:
      ```bash
      chezmoi execute-template --init --promptString hostname=<host> < home/.chezmoi.toml.tmpl
      chezmoi apply --dry-run --verbose --source . --destination /tmp/chezmoi-ci-<host>
      ```
      This is the mechanical check that would have caught the original
      `desktop`/`laptop` mismatch on a PR instead of at runtime on a real machine.
- [ ] Consider migrating any remaining custom encryption calls to chezmoi's
      native `age` support once `deprecated_encryption/` is gone (add `[age]`
      block to `.chezmoi.toml.tmpl` only when the migration is actually complete)

---

## Phase 6 — Full verification pass

Run against **every** host in `hosts.toml`, not just one:

```bash
for host in ubuntu-laptop ubuntu-24 vm-dev01; do
  echo "=== $host ==="
  chezmoi execute-template --init --promptString hostname=$host < home/.chezmoi.toml.tmpl
  chezmoi execute-template --init --promptString hostname=$host < home/.chezmoiignore.tmpl
  chezmoi execute-template --init --promptString hostname=$host < home/dot_bashrc.tmpl
done
```

Confirm for each:
- `role`/`gui`/`tags` render correctly, including the unknown-hostname fallback case
- GUI-only paths (`.local/bin/gui/`, `.config/autostart/`, `Templates/`) are excluded
  exactly when `gui=false`, regardless of role
- Role-only paths are excluded exactly when role doesn't match
- Fragments load correctly per role and per gui flag
- `packages.gui` / `tools.gui` only appear when `gui=true`

Only after this passes on every host: merge the branch, then do a real
`chezmoi apply --dry-run --verbose` on `ubuntu-24` and `god` before a live apply.

---

## Summary of what changes and why

| File | Change |
|---|---|
| `hosts.toml` | new — single source of truth for hostname → role/gui/tags |
| `.chezmoi.toml.tmpl` | derive role/gui/tags via `dig`, safe fallback |
| `roles.toml` | split GUI tools/packages out of role sections into `.gui` |
| `fragments.toml` | add `"gui"` as a valid context value |
| `.chezmoiignore.tmpl` | gate GUI paths on `.gui`, not `.role`; hostname check → role check |
| `run_once_before_01-install-packages.sh.tmpl` | merge in `packages.gui` when `.gui` |
| `run_once_after_20-gui-setup.sh.tmpl` | gate on `.gui`, fix `desktop/` → `gui/` path |
| `dot_local/bin/desktop/` | renamed to `dot_local/bin/gui/` |
| `deprecated_encryption/` | deleted |
| `future_plans/` | relocated out of repo root |
| `AGENTS.md` | rewritten to document role/gui split explicitly |
| CI | new — matrix-tests every hostname on every PR |
