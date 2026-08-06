Document every alias in the currently added/selected file using the repository shell documentation standard in `docs/shell-documentation-standard.md`.

Requirements:

- Do NOT change, rename, remove, reorder, or rewrite aliases.
- Do NOT modify the commands executed by aliases.
- Preserve existing section headings and organization.
- Add or improve documentation comments only.
- Infer `@category` from surrounding headings or module context where possible.
- Add `@description` and `@usage` for every public alias.
- Add `@requires`, `@example`, `@see`, and `@tags` only when useful.
- Do not add `@arg` unless the alias genuinely exposes a meaningful positional interface.
- Do not invent behavior that cannot be determined from the alias.
- Preserve `@internal` where present.
- Process the entire file.
