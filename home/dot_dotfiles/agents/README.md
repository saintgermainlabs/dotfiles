# Agent Instructions

This directory contains persistent instructions for coding agents that work on the dotfiles repository.

## Purpose

Use these files for rules about *how* agents should work in the repository.

Reusable one-off tasks belong in `../prompts/`.

The canonical shell annotation format is documented in:

- `../docs/shell-documentation-standard.md`

## Recommended usage

Keep a root-level `AGENTS.md` in the repository that points agents to the files in this directory.

Example:

```markdown
# Agent Instructions

See:

- `agents/aider.md`
- `agents/cursor.md`
- `agents/openclaw.md`
- `docs/shell-documentation-standard.md`
```
