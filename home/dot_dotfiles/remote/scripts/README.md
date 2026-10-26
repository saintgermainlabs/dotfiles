# remote/scripts

Remote-only scripts for role=remote hosts; not applied on the laptop.

Applied to `~/.dotfiles/remote/scripts/`. Gated by `.chezmoiignore.tmpl`
(`.dotfiles/remote/` is ignored when role != remote). Name executables
`executable_<name>.sh` so chezmoi sets +x.
