# OpenClaw Instructions

## Dotfiles documentation tasks

When OpenClaw is asked to document aliases or shell functions:

- Follow `docs/shell-documentation-standard.md`.
- Treat documentation changes as non-behavioral unless explicitly instructed otherwise.
- Preserve command names, ordering, shell semantics, and file organization.
- Inspect the complete function body before documenting arguments, exit codes, environment variables, or side effects.
- Use conservative descriptions when behavior is unclear.
- Never include secrets, API keys, tokens, passwords, or private key material in examples.
- Preserve or add `@internal` for helper functions that should be hidden from normal manual output.
