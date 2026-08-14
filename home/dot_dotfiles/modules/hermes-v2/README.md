# Hermes Gate shell module (hermes-v2)

Local Docker TUI client for [Hermes Gate](https://github.com/LehaoLin/hermes-gate).
It SSHs to a remote host, manages `gate-N` tmux sessions, and runs `hermes` on
the remote login PATH.

This module does **not** vendor upstream. `install.sh` clones it to
`~/.local/share/hermes-gate`. Remote CLI/config helpers stay in the `hermes`
module (`hm_*`).

## Requirements

- Docker on this laptop (the TUI runs in a local container)
- `git` and `ssh`
- SSH key in `~/.ssh/` authorized on the target host
- Remote login PATH must provide `tmux` and `hermes`

Optional: `notify-send` (libnotify) and `paplay`/`aplay` for desktop alerts.

## Enable

In `home/.chezmoidata/modules.toml`:

```toml
[modules.hermes-v2]
enabled = true
```

Then:

```bash
chezmoi apply
~/.dotfiles/modules/hermes-v2/install.sh
exec bash -l
hg_status
```

Laptop-only: ignored and not sourced when host `role` is not `local`.

## Everyday usage

```bash
# Clone once (skips docker build)
./install.sh

# Start the TUI (first run builds the hermes-gate image)
hg

# Maintenance
hg_rebuild
hg_update
hg_stop
hg_status
```

Inside the TUI, add a server using an SSH config alias or `user@host`:

```text
ubuntu
user@hostname
user@hostname:2222
```

Remote sessions keep running in tmux after you quit the TUI. Re-run `hg` to
reattach. The local Docker container stops when the last TUI session exits.

## Coexistence with `hm_*`

| Module | Purpose |
| --- | --- |
| `hermes` (`hm`, `hm_config_edit`, …) | SSH + `docker exec` into the Coolify Hermes container |
| `hermes-v2` (`hg`, …) | Local Hermes Gate TUI for remote tmux / `hermes` sessions |

Hermes Gate does not replace config download/upload. Use `hm_config_get` /
`hm_config_put` / `hm_config_edit` for `config.yaml`.

## Function reference

| Function | Purpose |
| --- | --- |
| `hg` / `hermes_gate` | Start the TUI (`./run.sh`) |
| `hg_rebuild` | Force rebuild the image, then start |
| `hg_update` | `git pull`, rebuild, then start |
| `hg_stop` | Stop and remove the container |
| `hg_status` | Clone + Docker status |
| `hg_dir` | Print the checkout path |

## Security

- Do not put tokens or API keys in this module.
- The Gate container mounts `~/.ssh` read-only.
- Upstream may deploy a `gate-notify` plugin under `~/.hermes/plugins/` on the
  remote host when you create a session.
