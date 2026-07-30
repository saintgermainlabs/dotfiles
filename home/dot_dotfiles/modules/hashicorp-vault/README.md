# HashiCorp Vault shell module

Reusable Bash and Zsh helpers for HashiCorp Vault. The module is designed for a
dotfiles repository and does not contain Vault tokens, AppRole Secret IDs, or
OIDC client secrets.

Defaults:

```text
VAULT_ADDR=https://vault.tiger-bushmaster.ts.net
VAULT_OIDC_ROLE=inventory
VAULT_TRANSIT_KEY=inventory
VAULT_APPROLE_NAME=py-server-manage
```

## Requirements

- `vault`
- `jq`
- `base64`

Run the dependency check:

```bash
./install.sh
```

## Installation

With chezmoi, enable `modules.hashicorp-vault` in `modules.toml` and run
`chezmoi apply`. `~/.bashrc` / `~/.zshrc` source `module.sh` via
`source-modules.tmpl` (no manual `source` line needed).

For a standalone checkout, add to `~/.bashrc` or `~/.zshrc`:

```bash
source "$HOME/path/to/dotfiles/modules/hashicorp-vault/module.sh"
```

## Configuration

Copy `vault.env.example` to a private, untracked location if overrides are
needed:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/vault"
cp vault.env.example \
  "${XDG_CONFIG_HOME:-$HOME/.config}/vault/environment"
chmod 600 "${XDG_CONFIG_HOME:-$HOME/.config}/vault/environment"
```

Load it before `module.sh`:

```bash
set -a
source "${XDG_CONFIG_HOME:-$HOME/.config}/vault/environment"
set +a
source "$HOME/path/to/dotfiles/modules/hashicorp-vault/module.sh"
```

Do not put `VAULT_TOKEN`, `VAULT_SECRET_ID`, or an Authentik client secret in
this file.

## Interactive OIDC login

```bash
vault_oidc_login
vault_whoami
```

This uses the `inventory` role by default:

```bash
vault_oidc_login another-role
```

## AppRole login

The safest convenient option is to provide credentials in protected files:

```bash
export VAULT_ROLE_ID_FILE=/run/secrets/vault_role_id
export VAULT_SECRET_ID_FILE=/run/secrets/vault_secret_id
vault_approle_login
```

Environment variables are also supported:

```bash
export VAULT_ROLE_ID="..."
export VAULT_SECRET_ID="..."
vault_approle_login
unset VAULT_ROLE_ID VAULT_SECRET_ID
```

For an interactive prompt that does not add credentials to shell history:

```bash
vault_approle_login_prompt
```

## Transit encryption

Encrypt a file:

```bash
vault_encrypt_file inventory.yaml inventory.yaml.vault
```

Decrypt it:

```bash
vault_decrypt_file inventory.yaml.vault inventory.yaml
```

Use a key other than `inventory`:

```bash
vault_encrypt_file input.yaml output.vault another-key
vault_decrypt_file output.vault restored.yaml another-key
```

Pipelines are supported:

```bash
printf '%s' 'secret text' | vault_encrypt
printf '%s' 'vault:v1:...' | vault_decrypt
```

Transit ciphertext such as `vault:v1:...` is safe to commit only when the
plaintext contains no metadata that must remain hidden outside the ciphertext
and the repository contains no Vault credentials. Access to the Transit decrypt
endpoint must remain tightly controlled.

## KV v2 helpers

```bash
vault_kv_get py-server-manage/example
vault_kv_get_field py-server-manage/example api_key
vault_kv_put py-server-manage/example api_key=value username=value
vault_kv_delete py-server-manage/example
vault_kv_list py-server-manage
```

The default KV mount is `secret`. Override it with `VAULT_KV_MOUNT`.

## Response wrapping

Unwrap a one-time wrapping token:

```bash
vault_unwrap
```

The function prompts securely. It prints the unwrapped response, so redirect it
carefully and never enable shell tracing around credentials.

## Function reference

| Function | Purpose |
| --- | --- |
| `vault_check` | Check dependencies, address, and Vault health |
| `vault_oidc_login [role]` | Interactive Authentik OIDC login |
| `vault_approle_login` | Login using environment variables or secret files |
| `vault_approle_login_prompt` | Prompt securely for Role ID and Secret ID |
| `vault_logout` | Revoke the current token when possible and unset it |
| `vault_whoami` | Show metadata for the current token |
| `vault_encrypt` | Encrypt stdin and print Transit ciphertext |
| `vault_decrypt` | Decrypt ciphertext from stdin |
| `vault_encrypt_file` | Encrypt a file atomically |
| `vault_decrypt_file` | Decrypt a file atomically |
| `vault_kv_get` | Read a KV v2 secret |
| `vault_kv_get_field` | Print one field from a KV v2 secret |
| `vault_kv_put` | Write KV v2 key/value pairs |
| `vault_kv_delete` | Delete the latest KV v2 version |
| `vault_kv_list` | List a KV v2 path |
| `vault_unwrap` | Securely prompt for and unwrap a wrapping token |

## Security rules

- Never commit Vault tokens, Secret IDs, or OIDC client secrets.
- Avoid passing credentials as command-line arguments.
- Keep credential files mode `0600` and outside the repository.
- Do not use `set -x` while authenticating or handling plaintext.
- Use AppRole for applications and OIDC for humans.
- Prefer short-lived batch tokens and wrapped Secret IDs for automation.
- Decrypted output is created with mode `0600`.

