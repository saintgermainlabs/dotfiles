# Task: Integrate 1Password CLI + Coolify CLI context into dotfiles repo

## Repo & conventions (read first)
This is a chezmoi-managed dotfiles repo (`saintgermainlabs/dotfiles`) with `.chezmoiroot = home`.
Existing conventions to follow — do not deviate from these patterns:
- Host detection lives in `home/.chezmoidata/hosts.toml`, keyed by hostname, with a `role`
  field (`desktop`/`server`) plus arbitrary boolean feature flags per host.
- Secrets are never stored in the repo, encrypted or otherwise, if 1Password can reach them.
  Use chezmoi's native `onepasswordRead "op://VAULT/ITEM/field"` template function inline in
  `.tmpl` files. Only fall back to `chezmoi add --encrypt` (age) for hosts where `op` isn't
  reachable.
- Version management is via `mise` exclusively — no manual PATH hacking, no asdf, no nvm etc.
- One-time setup / idempotent config commands run as `run_onchange_*.sh.tmpl` scripts under
  `home/.chezmoiscripts/`. These re-run only when their *rendered* content hash changes —
  exploit this by embedding a hash of a secret's current value as a comment when you need the
  script to re-run on credential rotation (see example below).
- The Coolify CLI (`coolify`, v1.6.2, github.com/coollabsio/coolify-cli) is already installed
  on the target host — do NOT add an install script for it.
- The Coolify CLI manages its own config at `~/.config/coolify/config.json` via its own
  `context` subcommands. Never template that JSON file directly — always shell out to
  `coolify context add` / `coolify context token` instead, so the CLI's own serialization
  logic (Viper) stays in control of that file.

## Part 1 — 1Password CLI integration

### Goal
Any host flagged for it in `hosts.toml` should have a working, signed-in `op` CLI available
before any `onepasswordRead` template calls run, and chezmoi scripts should fail loudly and
early if `op` isn't authenticated rather than silently writing an empty/broken value.

### Steps
1. Confirm `op` (1Password CLI) is present via `mise` where relevant, or already installed by
   Devin's environment where a manual system package makes more sense. If it's not managed by
   `mise` today elsewhere in this repo, check the repo's `mise.toml` / tool-versions files
   first — match whatever precedent exists before introducing a new tool-management pattern.
2. Add a small **preflight check script**,
   `home/.chezmoiscripts/run_before_check-1password-signin.sh.tmpl`, gated the same way other
   host-conditional scripts are (check `.chezmoidata.hosts` for the current hostname), that:
   - Runs `op whoami` (or equivalent lightweight auth check).
   - On failure, prints a clear message telling the human to run `op signin` (or unlock via
     the desktop app's CLI integration/biometric unlock) and exits non-zero, **before** any
     `onchange` scripts that call `onepasswordRead` get a chance to run and silently fail.
   - This must be a `run_before_` script (not `run_onchange_`) so it runs on every
     `chezmoi apply`, not just when its content changes — auth state isn't something we can
     hash-gate.
3. Confirm the 1Password vault referenced going forward (`SG-Labs`) actually exists and is
   reachable with `op vault list`. If it doesn't exist, do not create it — flag this back
   rather than guessing at vault structure, since vault organization is a human decision.

### Do NOT
- Do not store an `op` service account token in the repo, in an env var file, or in shell rc
  files. Interactive `op signin` / biometric unlock via the desktop app is the intended auth
  path on `god` (the primary desktop machine). If a server-context host later needs
  non-interactive 1Password access, that requires a **service account token** with scoped
  vault access — raise this as a separate decision point rather than implementing it
  unprompted, since it changes the security model.

## Part 2 — Coolify CLI context configuration

### Goal
On hosts flagged `coolify_cli = true`, ensure a `homelab` context exists in the Coolify CLI's
config pointing at `https://coolify.tiger-bushmaster.ts.net`, with the token sourced live from
1Password (`op://SG-Labs/Coolify API/token`) — never hardcoded, never committed.

### Steps
1. In `home/.chezmoidata/hosts.toml`, ensure the primary desktop host entry has:
```toml
   [hosts.god]
   role = "desktop"
   coolify_cli = true
```
   Do not add this flag to server hosts (`ubuntu-24`, `ubuntu-server`) unless explicitly told
   to — this CLI is being run from the desktop against the homelab's Coolify instance, not
   from the homelab itself.

2. Create `home/.chezmoiscripts/run_onchange_configure-coolify-context.sh.tmpl`:

```bash
   #!/usr/bin/env bash
   set -euo pipefail

   {{- if (index .chezmoidata.hosts .chezmoi.hostname).coolify_cli }}
   # Re-run when the stored token changes:
   # COOLIFY_TOKEN_HASH: {{ onepasswordRead "op://SG-Labs/Coolify API/token" | sha256sum }}

   COOLIFY_URL="https://coolify.tiger-bushmaster.ts.net"
   COOLIFY_TOKEN="{{ onepasswordRead "op://SG-Labs/Coolify API/token" }}"

   if coolify context list 2>/dev/null | grep -q '^homelab'; then
     coolify context token homelab "$COOLIFY_TOKEN"
   else
     coolify context add homelab "$COOLIFY_URL" "$COOLIFY_TOKEN"
   fi

   coolify context use homelab
   {{- else }}
   echo "Skipping coolify context setup on {{ .chezmoi.hostname }}"
   {{- end }}
```

3. Make sure this script only executes **after** the 1Password preflight check from Part 1 —
   chezmoi runs scripts in lexical order within their category (`run_before_` before
   `run_onchange_`), so no explicit dependency wiring should be needed, but verify this by
   checking execution order in `chezmoi apply --dry-run --verbose` output.

### Verification steps (must pass before considering this done)
```bash
chezmoi apply --dry-run --verbose   # confirm script would run, review rendered output
chezmoi apply                       # actually apply
coolify context list                # confirm "homelab" appears
coolify context use homelab && coolify server list   # confirm token actually authenticates
```
If `coolify server list` fails with an auth error, the token in 1Password
(`op://SG-Labs/Coolify API/token`) is wrong or the vault path doesn't match — do not
hardcode a working token as a workaround; fix the 1Password item instead.

## Constraints / non-negotiables
- No secrets committed to the repo in any form, plaintext or otherwise, for this task.
- No changes to unrelated existing scripts or `hosts.toml` entries beyond what's specified.
- If `op://SG-Labs/Coolify API/token` doesn't exist as a 1Password item, stop and report
  back rather than creating a placeholder or guessing the item name.
- Open a PR rather than pushing directly to main, per whatever branch convention the repo
  already uses (check for a `CONTRIBUTING.md` or existing PR history pattern first).
