# Dotfiles Remediation — Implementation Status

Last updated: 2026-07-07

This document tracks progress against `dotfiles-remediation-plan.md` (detailed
plan: `~/.windsurf/plans/repo-cleanup-remediation-9d38f8.md`), plus the earlier
encryption-removal work that preceded it.

---

## Phase 0 — Encryption removal (pre-plan work) ✅ DONE

- Moved all encryption-related files (`age` key install script, coolify context
  script, `render-secrets`, `dot_env` with 1Password tokens, `hosts.yaml`,
  `dot_dotfiles/secrets`) into a `deprecated_encryption/` folder.
  **User has since deleted that folder entirely.**
- Removed `age` from `[packages.common]` and `lastpass-cli` from laptop packages.
- Removed `AGE_IDENTITY` from `dot_dotfiles/common/.env.example`.
- Removed `.env` / `secrets/` / `.private/` sourcing loops from
  `dot_bashrc.tmpl`, `dot_zshrc.tmpl`, and `dot_dotfiles/zsh/rc`.
- Fixed `.chezmoiroot` (was wrongly a `.chezmoiroot.tmpl` containing ignore
  rules; now contains just `home`).
- Added `deprecated_encryption/` to `.gitignore` as a safety net.
- Fixed template errors: `readFile` → `include`, `fromTOML` → `fromToml`.

## Phase 1 — Data model: split `role` from `gui` ✅ DONE

- **`home/.chezmoi.toml.tmpl`** rewritten:
  - Reads `home/.chezmoidata/hosts.toml` **directly** via
    `joinPath .chezmoi.sourceDir ".chezmoidata/hosts.toml" | include | fromToml`.
    (Discovered during verification: `.chezmoidata` is *not* available while
    chezmoi renders the config template, so `.hosts` had to be loaded manually.)
  - Uses `dig` with safe fallbacks: unknown hostnames get `role="server"`,
    `gui=false`, `tags=[]` — the least-privileged default.
  - Sets `git_email = "saintgermainlabs@gmail.com"`.
  - Supports a `DOTFILES_HOSTNAME` env-var override so CI/tests can render the
    config as if on another host. (First attempt used `CHEZMOI_HOSTNAME`, which
    chezmoi sets itself and clobbers — renamed to avoid the collision.)
- **`home/.chezmoidata/hosts.toml`** (created by user, kept as-is): defines
  `ubuntu-laptop` (laptop, gui), `ubuntu-24` (server, no gui), `vm-dev01`
  (vm, no gui).
- **`home/.chezmoidata/roles.toml`**: GUI packages (`nautilus`,
  `nautilus-image-converter`, `wl-clipboard`, `zenity`) moved from
  `[packages.laptop]` into a new `[packages.gui]`; empty `[tools.gui]` section
  added for future GUI-only tools; `[packages.laptop]` now empty
  (role-specific, non-GUI only).
- **`home/.chezmoidata/fragments.toml`**: documented `"gui"` as a valid
  fragment context alongside the three roles.

## Phase 2 — Rename `desktop` → `gui` ✅ DONE

- `home/dot_local/bin/desktop/` → `home/dot_local/bin/gui/` (plain `mv`;
  `git mv` failed because the dir contents were untracked — **remember to
  `git add` the new path**).
- All remaining `desktop` references in templates updated (ignore file,
  GUI setup script).

## Phase 3 — Fix consumers ✅ DONE

- **`home/.chezmoiignore.tmpl`**:
  - GUI paths (`.local/bin/gui/`, `.config/autostart/`, `Templates/`) now
    gated on `{{ if not .gui }}` instead of role.
  - Role paths gated per role; removed the hostname-hardcoded
    `ubuntu-laptop` rule for `.chezmoiscripts/laptop` (now keyed on `.role`).
  - Dropped redundant repo-metadata ignores (`AGENTS.md`, `README.md`, etc.)
    that no longer live under `home/`.
- **`home/.chezmoiscripts/run_once_before_01-install-packages.sh.tmpl`**:
  merges `packages.gui` into the apt list when `.gui` is true.
- **`home/.chezmoiscripts/run_once_after_20-gui-setup.sh.tmpl`**: gated on
  `{{ if not .gui }}exit 0{{ end }}`, references `~/.local/bin/gui/`.
- **`home/dot_config/mise/config.toml.tmpl`**: uses
  `merge .tools.common (index .tools .role)` plus `.tools.gui` when `.gui`.
- **`home/.chezmoitemplates/load-fragments.tmpl`** (new): shared loader that
  enables a fragment when its context list contains the host's role, or
  contains `"gui"` and the host has `gui=true`.
- **`home/dot_bashrc.tmpl`** and **`home/dot_zshrc.tmpl`**: both now call
  `{{ template "load-fragments.tmpl" . }}` instead of duplicating logic.

## Phase 4 — Delete / relocate dead weight ✅ DONE

- `deprecated_encryption/` — confirmed gone (deleted by user).
- `future_plans/` — already gone (does not exist).
- `dotfiles-chezmoi-mise-guide.md` moved to `docs/`.
- `AGENTS.md` fully rewritten: documents `.chezmoiroot`/`home/` layout, the
  role-vs-gui distinction ("never conflate these"), a table of where each
  concern is declared, and updated testing/definition-of-done sections.

## Phase 5 — Guardrails ✅ DONE

- **`.chezmoiversion`** added (`2.66.0`, matching the installed version).
- **`.mise.toml`** at repo root: `shellcheck` + `shfmt` for linting.
- **`.github/workflows/chezmoi.yml`**: CI matrix over
  `ubuntu-laptop / ubuntu-24 / vm-dev01 / unknown-host`; each job runs
  `chezmoi init` (config render) and `chezmoi apply --dry-run` with
  `DOTFILES_HOSTNAME` set. *Not yet exercised on GitHub — will validate on
  first push.*

## Phase 6 — Verification 🔶 IN PROGRESS

Done:

- ✅ Config template renders correctly for all four hosts
  (via `DOTFILES_HOSTNAME=<host> chezmoi init`):

  | host | role | gui | tags |
  |---|---|---|---|
  | ubuntu-laptop | laptop | true | personal, primary |
  | ubuntu-24 | server | false | homelab, coolify-host |
  | vm-dev01 | vm | false | ephemeral |
  | unknown-host | server | false | (empty) |

- ✅ `chezmoi ignored` per host: GUI paths (`.local/bin/gui`, `Templates`)
  excluded exactly when `gui=false`; role dirs excluded for non-matching roles.
- ✅ Mise tools merge per host: laptop gets terraform/lazydocker; server gets
  lazygit/starship; vm gets lazygit only.
- ✅ Fragment loader renders `docker_functions` correctly in `.bashrc`.
- ✅ Package script includes the four GUI packages on `gui=true` hosts.
- ✅ Local config re-initialized for the real host (`ubuntu-laptop`,
  role=laptop, gui=true).

Remaining:

- ⬜ `chezmoi diff` review (last attempt canceled by user).
- ⬜ `chezmoi apply --dry-run`, then `chezmoi apply`.
- ⬜ `chezmoi doctor`.
- ⬜ Source `.bashrc` / `.zshrc` in a fresh shell; sanity-check
  `~/.config/mise/config.toml` on disk.
- ⬜ `git add` everything (incl. the renamed `home/dot_local/bin/gui/`),
  review `git status`, and commit.
- ⬜ Push and confirm the GitHub Actions workflow passes.

---

## Notable gotchas discovered along the way

1. **`.chezmoidata` is not available in `.chezmoi.toml.tmpl`** — the config
   template must `include` + `fromToml` the hosts file itself.
2. **`CHEZMOI_HOSTNAME` is reserved** — chezmoi exports it itself, silently
   overriding any value you set; use a custom var (`DOTFILES_HOSTNAME`).
3. **`git mv` fails on untracked dirs** — the `desktop` → `gui` rename used
   plain `mv`; the new path still needs `git add`.
4. Template function names differ from other Go tooling: `include` (not
   `readFile`), `fromToml` (not `fromTOML`).
