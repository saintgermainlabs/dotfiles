# AGENTS.md

This repository manages personal configuration with Chezmoi only.
Every change must be safe to re-apply with `chezmoi apply`.

## Rule

DO NOT DELETE FILES WITHOUT MY AUTHORIZATION


## Scope


Chezmoi owns **dotfiles and config files**.

PATH and environment variables are data-driven and owned by chezmoi:

- `home/.chezmoidata/paths.toml` — PATH entries, rendered by `.chezmoitemplates/paths.tmpl`
- `home/.chezmoidata/env.toml` — exported variables, written by `.chezmoiscripts/run_after_20-export-env.sh.tmpl`

Add to them with `chezmoi_add_path` and `chezmoi_add_env` (in `dot_dotfiles/common/utils/`), not by hand-editing PATH logic.

Do **not** add:

- apt / package install scripts
- `mise install` scripts
- PATH logic outside `paths.toml` / `paths.tmpl`
- environment bootstrapping beyond those data files and tiny role defaults

mise owns tool installs (`conf.d/dotfiles.toml`). The workstation provisioner owns
desktop app installs (VS Code, Cursor, Sublime, chezmoi binary, etc.).

## Agent instruction files

This file is the index. Tool-specific rules live beside the shell sources:

- `home/dot_dotfiles/agents/aider.md` — shell documentation rules for aider
- `home/dot_dotfiles/agents/cursor.md`
- `home/dot_dotfiles/agents/openclaw.md`
- `home/dot_dotfiles/docs/shell-documentation-standard.md` — the annotation format all of them follow

## Checks

Run `tests/check.sh` before committing. It renders every template, syntax-checks the scripts,
and parses every `.chezmoidata` file.

### mise config split

- `~/.config/mise/config.toml` — hand-written / Omakub base; **never** managed by chezmoi
- `~/.config/mise/conf.d/dotfiles.toml` — chezmoi-managed additive tools only

Do not add a template that writes `config.toml`; that would wipe existing tools.

## Axes — never conflate these

- **role**: `local` (laptop) or `remote` (headless server)
- **gui**: boolean — whether GUI modules may apply

Gate GUI paths on `.gui` (and module toggles), never on `role == "local"`.

## Module toggles

Edit `home/.chezmoidata/modules.toml`, then `chezmoi apply`.

`.chezmoiignore.tmpl` ignores disabled modules and all GUI paths when `gui = false`.

## ToFpon Nautilus extensions (PPA)

Python extensions from [ToFpon/Nautilus-Extensions](https://github.com/ToFpon/Nautilus-Extensions) are **not** vendored in this repo. Toggle packages in [`home/.chezmoidata/nautilus-extensions.toml`](home/.chezmoidata/nautilus-extensions.toml) and enable [`modules.nautilus_extensions`](home/.chezmoidata/modules.toml). Chezmoi renders `~/.config/dotfiles/nautilus-extensions.toml` for the **workstation provisioner** (PPA + `apt install` + `nautilus-extensions-tof-link`).

Separate from **cfgnunes** bash scripts under `modules.nautilus` (`~/.local/share/nautilus/scripts/`). Both can be enabled independently.

Do not add apt/PPA install scripts to chezmoi. Extension enable/disable at runtime is owned by upstream **Extensions Manager** (`~/.local/share/nautilus-python/extensions/disabled/`).

### Optional shell modules (`~/.dotfiles/modules/<name>/`)

Toggle in `modules.toml`. Chezmoi applies the directory; bash/zsh load **`module.sh`** when present (otherwise `functions.sh` / `aliases.sh`, or legacy `functions` for docker). **`install.sh` is not sourced** — run from the workstation provisioner or manually. Document mise/apt deps in `dependencies.toml`; render CLI tools into `conf.d/dotfiles.toml` when `modules.mise` is on.

Example: `hashicorp-vault/` with `module.sh`, `functions.sh`, `aliases.sh`, `install.sh`, `vault.env.example`, `README.md`.

## Layout

```text
home/
├── .chezmoidata/       # hosts + modules + dependencies + nautilus-extensions (never applied)
├── .chezmoi.toml.tmpl
├── .chezmoiignore.tmpl
├── .chezmoitemplates/
├── dot_config/
├── dot_dotfiles/
├── dot_local/          # cfgnunes nautilus scripts (modules.nautilus)
└── private_dot_ssh/
```

## Principles

1. Never store secrets in the repository.
2. Prefer templates over duplicated files.
3. Keep host-specific data in `hosts.toml`.
4. All changes must be idempotent under `chezmoi apply`.
5. Prefer adding a module over growing `common/` indefinitely.
