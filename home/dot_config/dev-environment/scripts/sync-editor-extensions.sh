#!/bin/bash

set -uo pipefail

extension_file="${XDG_CONFIG_HOME:-$HOME/.config}/dev-environment/extensions.txt"

if [[ ! -f "$extension_file" ]]; then
    printf 'Extension manifest not found: %s\n' "$extension_file" >&2
    exit 1
fi

editors=(
    "cursor:Cursor"
    "code:Visual Studio Code"
    "windsurf:Windsurf"
    "codium:VSCodium"
)

install_extensions() {
    local editor_command="$1"
    local editor_name="$2"
    local installed
    local extension

    if ! command -v "$editor_command" >/dev/null 2>&1; then
        printf 'Skipping %s: command %s not found\n' \
            "$editor_name" "$editor_command"
        return 0
    fi

    printf '\nSynchronizing %s\n' "$editor_name"

    installed="$("$editor_command" --list-extensions 2>/dev/null || true)"

    while IFS= read -r extension || [[ -n "$extension" ]]; do
        # Remove surrounding whitespace.
        extension="${extension#"${extension%%[![:space:]]*}"}"
        extension="${extension%"${extension##*[![:space:]]}"}"

        # Ignore comments and empty lines.
        [[ -z "$extension" || "$extension" == \#* ]] && continue

        if grep -Fxiq "$extension" <<<"$installed"; then
            printf '  Installed: %s\n' "$extension"
        else
            printf '  Installing: %s\n' "$extension"

            if ! "$editor_command" --install-extension "$extension"; then
                printf '  Unavailable in %s: %s\n' \
                    "$editor_name" "$extension" >&2
            fi
        fi
    done <"$extension_file"
}

for editor in "${editors[@]}"; do
    install_extensions "${editor%%:*}" "${editor#*:}"
done
