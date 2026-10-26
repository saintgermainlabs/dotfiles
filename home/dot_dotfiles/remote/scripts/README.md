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
