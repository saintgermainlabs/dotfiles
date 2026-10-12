# Aider Instructions

## Shell documentation

When documenting shell aliases or functions:

1. Follow `home/dot_dotfiles/docs/shell-documentation-standard.md`.
2. Do not modify runtime behavior unless explicitly requested.
3. Do not rename, remove, or reorder commands.
4. Preserve existing headings and organization.
5. Inspect the full function body before documenting a function.
6. Document behavior conservatively when intent is ambiguous.
7. Never include secret values, tokens, passwords, or credentials in examples.
8. Prefer concise, stable category names.
9. Use `@internal` for helper functions that should normally be hidden from the manual.
10. Review the diff to ensure changes are documentation-only unless behavior changes were explicitly requested.

## Quality checks

When practical:

- Run `shellcheck` on modified shell files.
- Verify examples match the actual command interface.
- Ensure `@usage` describes invocation of the alias/function itself, not merely the expanded command.
