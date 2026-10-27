# remote/scripts

Remote-only scripts for role=remote hosts; not applied on the laptop.

Applied to `~/.dotfiles/remote/scripts/`. Gated by `.chezmoiignore.tmpl`
(`.dotfiles/remote/` is ignored when role != remote). Name executables
`executable_<name>.sh` so chezmoi sets +x.

## Scripts

- `coolify-inventory.sh [out.yaml]` — prints a big **REMOTE SERVER** banner, shows
  `tree` of `/data/coolify/{services,applications}`, then parses every
  `docker-compose.y(a)ml` and writes a YAML inventory (stack → compose file →
  service name/image/container_name). Default out: `~/coolify-inventory.yaml`
  (override with arg or `COOLIFY_INVENTORY_OUT`; root via `COOLIFY_ROOT`).
  May need `sudo` to read `/data/coolify`.
- `coolify-inventory.sh summary [--refresh] [--tsv] [file]` — readable tree of projects/stacks/services from the raw inventory (alias: `list`). stack_name = docker label `app.name` (whole stack; falls back to coolify.resourceName, compose project, id); shown as `stack: NAME` in text, `stack_name` TSV column; `app.component` stays per-service.
  Add `--yaml` (or `--format yaml`; also `--format tsv|text`) for structured YAML: `projects.<project>.stacks.<stack_name>.{stack_name,id,root,environment,stack_dir,compose_files,services.<service>.{stack_name,stack_id,component,image,container_name,running,working_dir,build_context,env_file,volumes,live_mounts}}` — path fields merged from `coolify-paths.yaml` (`COOLIFY_PATHS_IN`) when present. `--by-name` writes `~/data/inv/coolify-by-name.yaml`; `--out=FILE` custom; `--refresh --yaml` also regenerates paths. Works identically for `summary` and `list`.
- `coolify-inventory.sh get <stack_name> [component]` (alias `lookup`, or `--name X --component Y`) — prints the YAML block for that stack (`app.name`), or just the matching service (`app.component`, falling back to service key), from `~/data/inv/coolify-by-name.yaml` (`--file=F`; `-r/--refresh` regenerates; auto-generated if missing). Unknown name/component lists what's available.
