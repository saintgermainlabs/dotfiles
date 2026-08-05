# local_to_remote

A Bash dotfile module for safely operating on a configured remote server.

## Features

- Execute arbitrary commands remotely.
- Open an interactive SSH shell.
- Upload files/directories with rsync.
- Download files/directories with rsync.
- Maintain an explicit allowlist of editable remote configuration files.
- Download an approved config file, edit it locally, back up the remote copy,
  and upload the changed version.
- Show and back up approved remote files.
- Execute a locally defined Bash function remotely with `rfunc`.
- Structured `@name`, `@category`, `@summary`, `@usage`, `@arg`, `@example`,
  and `@description` annotations for automatic help generation.

## Suggested dotfile structure

```text
dotfiles/
└── home/
    ├── private_dot_config/
    │   └── local_to_remote/
    │       └── config.sh
    └── private_dot_local/
        └── share/
            └── shell/
                └── modules/
                    └── local_to_remote.sh
```

Or use whatever module layout your current dotfile repository already follows.

## Install

Source the module from `.bashrc` or another shell loader:

```bash
source "$HOME/.local/share/shell/modules/local_to_remote.sh"
```

Copy `config.example.sh` to:

```text
~/.config/local_to_remote/config.sh
```

and edit:

```bash
LTR_REMOTE_HOST="ubuntu-server"
LTR_EDITOR="subl -w"
```

The host should normally be an alias defined in `~/.ssh/config`.

## Commands

```bash
remote_cmd hostname
remote_cmd docker ps

remote_shell

remote_upload ./file.txt /srv/example/file.txt
remote_download /srv/example/file.txt ./file.txt

remote_files
remote_show openclaw-config
remote_edit openclaw-config
remote_backup_file openclaw-config

rfunc container_id openclaw application
r container_id openclaw application
```

## Safe configuration editing

`remote_edit` does not accept a remote path directly.

This is intentional.

Only keys declared in `LTR_ALLOWED_FILES` can be edited:

```bash
declare -A LTR_ALLOWED_FILES=(
    ["openclaw-config"]="/data/.openclaw/openclaw.json"
    ["openclaw-compose"]="/srv/apps/openclaw/compose.yaml"
)
```

Then:

```bash
remote_edit openclaw-config
```

performs:

```text
remote server
    ↓
download approved file
    ↓
temporary local file
    ↓
Sublime Text
    ↓
detect changes
    ↓
remote timestamped .bak
    ↓
upload edited file
```

If the editor exits without changing the file, nothing is uploaded.

## Sublime Text

Use:

```bash
LTR_EDITOR="subl -w"
```

The `-w` option makes the command wait for Sublime Text to finish editing before
the module continues.

## Notes about permissions

The remote SSH account must have read/write permission for any approved path.

If a configuration file exists inside a Docker container rather than on the
host, prefer bind-mounting the config onto the host. That makes configuration
management, backup, inspection, and editing substantially cleaner.

For files that truly must stay inside a container, add a separate container-aware
editor helper rather than putting `docker cp` logic into the normal file editor.
