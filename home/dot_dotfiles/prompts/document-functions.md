Document every shell function in the currently added/selected file using the repository shell documentation standard in `docs/shell-documentation-standard.md`.

Requirements:

- Inspect each full function body before documenting it.
- Do NOT modify behavior unless explicitly requested.
- Do NOT rename, remove, or reorder functions.
- Preserve existing headings and organization.
- Add `@category`, `@description`, and `@usage` for each public function.
- Add meaningful `@arg`, `@option`, `@env`, `@exitcode`, `@stdin`, `@stdout`, `@stderr`, `@requires`, `@example`, `@see`, and `@tags` annotations where applicable.
- Document actual behavior conservatively.
- Preserve `@internal` for helper functions.
- Do not expose secret values in examples.
- Process the entire file.
