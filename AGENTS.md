# AGENTS.md

This repository manages personal configuration with Chezmoi only.
Every change must be safe to re-apply with `chezmoi apply`.

## Scope

Chezmoi owns **dotfiles and config files**.

Do **not** add:

- apt / package install scripts
- `mise install` scripts
- PATH rewriting
- environment bootstrapping beyond tiny role defaults

mise owns tools, PATH, and tool environment. The workstation provisioner owns
desktop app installs (VS Code, Cursor, Sublime, chezmoi binary, etc.).

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

## Tool dependencies (mise)

`home/.chezmoidata/dependencies.toml` maps **modules → mise tools** (and documents
**system** packages that mise does not install). When `modules.mise` is enabled,
chezmoi merges `[dependencies.<module>.tools]` (plus `roles.local` / `roles.remote`
extras) for every **active** module into `~/.config/mise/conf.d/dotfiles.toml`.

| File | Purpose |
|------|---------|
| `dependencies.toml` | Per-module mise tool versions; optional `requires_gui`, `roles.*`, `system` notes |
| `modules.toml` | Which dotfiles modules apply on this machine |
| `hosts.toml` | `role` and `gui` per hostname |

Do not duplicate module toggles in `dependencies.toml`. The obsolete `tools.toml`
duplicate was removed; use `dependencies.toml` only.

### `dependencies.toml` schema

```toml
[dependencies.<module>]
description = "optional"
requires_gui = true          # optional; skip tools when host gui = false

[dependencies.<module>.tools]
<mise-tool> = "<version>"    # e.g. "latest" or a pinned version

[dependencies.<module>.roles.local]   # or roles.remote
<mise-tool> = "<version>"    # merged only when host role matches

[dependencies.<module>.system]
<package> = "why provisioner/apt"   # not written to mise; documentation only
```

Merge rules (in `home/.chezmoi.toml.tmpl` → `data.mise_tools`):

1. `modules.mise` must be active or no tools are emitted.
2. For each other active module (sorted by name), merge `tools` then `roles.<role>`.
3. Later modules override the same tool name (deterministic order).
4. Entries with `requires_gui = true` are skipped when `gui = false`.

## Layout

```text
home/
├── .chezmoidata/       # hosts + modules + dependencies (never applied)
├── .chezmoi.toml.tmpl
├── .chezmoiignore.tmpl
├── .chezmoitemplates/
├── dot_config/
├── dot_dotfiles/
└── private_dot_ssh/
```

## Principles

1. Never store secrets in the repository.
2. Prefer templates over duplicated files.
3. Keep host-specific data in `hosts.toml`.
4. All changes must be idempotent under `chezmoi apply`.
5. Prefer adding a module over growing `common/` indefinitely.
