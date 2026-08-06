# Shell Documentation Standard

This document defines the annotation format used by the dotfiles manual system.

The goal is to keep aliases and functions self-documenting, searchable, categorizable, and suitable for rendering in terminal help, `fzf`, Markdown, or other generated documentation.

## Core principles

1. The shell source is the source of truth.
2. Documentation lives immediately above the alias or function it describes.
3. Documentation-only changes must not alter command behavior.
4. Use concise, stable categories and descriptions.
5. Only include annotations that are meaningful.
6. Never document secrets, credentials, tokens, passwords, or private key contents.
7. Mark implementation helpers with `@internal` so they can be hidden from the normal manual.

## Supported annotations

### `@category`

Groups the command in the manual.

```bash
## @category Git
```

Prefer stable categories such as:

- Archives
- Chezmoi
- Development
- Docker
- Files
- Git
- Navigation
- Networking
- OpenClaw
- Packages
- Python
- SSH
- System
- Tailscale

Avoid creating multiple names for the same concept.

### `@description`

A concise explanation of what the command does.

```bash
## @description Shows the current Git working tree and staging status.
```

Descriptions should explain the result or purpose, not merely restate the command name.

### `@usage`

Shows how the alias or function is invoked.

```bash
## @usage mkcd <directory>
```

Use common notation:

- `<value>` — required
- `[value]` — optional
- `[options]` — optional flags/options
- `<value>...` — one or more values

### `@arg`

Documents positional arguments.

```bash
## @arg $1 string The directory path to create and enter.
## @arg $2 string The destination archive path.
```

Recommended types include:

- `string`
- `integer`
- `path`
- `file`
- `directory`
- `boolean`
- `array`

For variadic arguments:

```bash
## @arg $@ string Commit message words.
```

### `@option`

Documents flags parsed by the function.

```bash
## @option -f Force the operation.
## @option --dry-run Show what would happen without making changes.
```

### `@env`

Documents environment variables used by the command.

```bash
## @env DF_DIR Root directory of the dotfiles checkout.
```

Document the variable's purpose, never its secret value.

### `@exitcode`

Documents meaningful return codes.

```bash
## @exitcode 0 If the operation succeeds.
## @exitcode 1 If the requested resource is missing.
## @exitcode 2 If usage is invalid.
```

Do not invent exit codes that the function does not deliberately return.

### `@stdin`

Documents input read from stdin or interactive prompts.

```bash
## @stdin Prompts for confirmation before pushing.
```

### `@stdout`

Documents meaningful standard output.

```bash
## @stdout Prints the generated public SSH key.
```

### `@stderr`

Documents meaningful errors or diagnostic output.

```bash
## @stderr Prints usage and validation errors.
```

### `@requires`

Documents external dependencies.

```bash
## @requires git
## @requires fzf
```

Use this for non-shell commands the alias/function depends on.

### `@example`

Provides realistic invocation examples.

```bash
## @example mkcd ~/projects/example
## @example addcommitpush "Update documentation"
```

Examples must be safe and must not include real credentials or secrets.

### `@see`

References related commands or manual pages.

```bash
## @see git-status(1)
## @see tar(1)
```

### `@tags`

Adds searchable keywords that may not appear in the name or description.

```bash
## @tags container inspect debug
```

Use short, useful search terms.

### `@internal`

Marks an implementation helper that should be hidden from normal manual output.

```bash
## @internal
```

## Alias template

```bash
## @category Git
## @description Shows the current Git working tree and staging status.
## @usage gs
## @requires git
## @see git-status(1)
alias gs='git status'
```

For an alias that accepts additional arguments naturally:

```bash
## @category Files
## @description Lists files in a detailed human-readable format.
## @usage ll [path]
## @requires eza
## @example ll ~/projects
alias ll='eza -lah'
```

Do not use `@arg` for simple aliases unless the alias has a genuine, meaningful positional interface.

## Function template

```bash
## @category Navigation
## @description Creates a directory and changes into it.
## @usage mkcd <directory>
## @arg $1 directory The directory path to create and enter.
## @exitcode 0 If the directory is created and entered successfully.
## @exitcode 1 If mkdir or cd fails.
## @exitcode 2 If the argument count is invalid.
## @stderr Prints usage information when called incorrectly.
## @example mkcd ~/projects/example
## @see mkdir(1)
mkcd() {
  if [ "$#" -ne 1 ]; then
    printf 'Usage: mkcd <directory>\n' >&2
    return 2
  fi

  mkdir -p -- "$1" && cd -- "$1"
}
```

## Internal helper template

```bash
## @internal
## @category Manual
## @description Collects shell files scanned by the manual system.
_manual_files() {
  ...
}
```

## Function documentation workflow

When documenting a function:

1. Read the complete function body.
2. Identify required and optional arguments.
3. Identify flags/options.
4. Identify environment variables.
5. Identify explicit return codes.
6. Identify external commands.
7. Identify stdin/stdout/stderr behavior.
8. Add realistic examples.
9. Add useful tags and references.
10. Confirm documentation matches the implementation.

## Alias documentation workflow

When documenting an alias:

1. Read the alias expansion.
2. Infer its purpose conservatively.
3. Use surrounding headings or module context for `@category`.
4. Add `@description`.
5. Add invocation syntax with `@usage`.
6. Add dependencies and references where useful.
7. Do not rewrite or optimize the alias during a documentation-only task.

## Manual behavior

The manual should ideally use these annotations to support:

```text
manual
manual <search>
manual <exact-command>
manual --category <category>
manual --functions
manual --aliases
manual --all
manual --fzf
```

A compact index should primarily group commands by `@category`.

An exact command match should show detailed fields including:

- command name
- type
- category
- description
- usage
- arguments
- options
- environment variables
- exit codes
- stdin/stdout/stderr
- requirements
- examples
- related references
- tags
- source file
