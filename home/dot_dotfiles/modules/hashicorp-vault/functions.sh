# shellcheck shell=bash
#
# HashiCorp Vault helpers compatible with Bash and Zsh.

: "${VAULT_ADDR:=https://vault.tiger-bushmaster.ts.net}"
: "${VAULT_OIDC_ROLE:=inventory}"
: "${VAULT_TRANSIT_MOUNT:=transit}"
: "${VAULT_TRANSIT_KEY:=inventory}"
: "${VAULT_KV_MOUNT:=secret}"
: "${VAULT_APPROLE_MOUNT:=approle}"
: "${VAULT_APPROLE_NAME:=py-server-manage}"

export VAULT_ADDR

## @internal
## @category HashiCorp Vault
## @description Print an error message to stderr
## @usage _vault_error <message>
## @arg $1 string Error message to display
## @stderr Error message with prefix
_vault_error() {
  printf 'vault-helper: %s\n' "$*" >&2
}

## @internal
## @category HashiCorp Vault
## @description Check if a required command is available
## @usage _vault_require_command <command>
## @arg $1 string Command name to check
## @exitcode 0 If command is available
## @exitcode 127 If command is not found
## @stderr Error message if command not found
_vault_require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    _vault_error "required command not found: $1"
    return 127
  }
}

## @internal
## @category HashiCorp Vault
## @description Check if all required tools are available
## @usage _vault_require_tools
## @requires vault
## @requires jq
## @requires base64
## @exitcode 0 If all tools are available
## @exitcode 127 If any tool is missing
## @stderr Error message for missing tools
_vault_require_tools() {
  _vault_require_command vault &&
    _vault_require_command jq &&
    _vault_require_command base64
}

## @internal
## @category HashiCorp Vault
## @description Read a credential from environment variable or file
## @usage _vault_read_credential <variable_name> <file_variable_name>
## @arg $1 string Environment variable name containing the credential
## @arg $2 string Environment variable name containing the credential file path
## @stdout The credential value
## @exitcode 0 If credential is successfully read
## @exitcode 1 If neither variable is set or file is not readable
## @stderr Error messages for missing or unreadable credentials
_vault_read_credential() {
  _vault_credential_variable=$1
  _vault_credential_file_variable=$2

  eval "_vault_credential_value=\${${_vault_credential_variable}:-}"
  if [ -n "$_vault_credential_value" ]; then
    printf '%s' "$_vault_credential_value"
    unset _vault_credential_variable _vault_credential_file_variable
    unset _vault_credential_value
    return 0
  fi

  eval "_vault_credential_file=\${${_vault_credential_file_variable}:-}"
  if [ -n "$_vault_credential_file" ]; then
    if [ ! -r "$_vault_credential_file" ]; then
      _vault_error "credential file is not readable: $_vault_credential_file"
      unset _vault_credential_variable _vault_credential_file_variable
      unset _vault_credential_value _vault_credential_file
      return 1
    fi
    IFS= read -r _vault_credential_value <"$_vault_credential_file" || {
      _vault_error "could not read credential file: $_vault_credential_file"
      return 1
    }
    printf '%s' "$_vault_credential_value"
    unset _vault_credential_variable _vault_credential_file_variable
    unset _vault_credential_value _vault_credential_file
    return 0
  fi

  unset _vault_credential_variable _vault_credential_file_variable
  unset _vault_credential_value _vault_credential_file
  return 1
}

## @category HashiCorp Vault
## @description Check Vault status and connection
## @usage vault_check
## @requires vault
## @stdout Vault address and status information
## @see vault-status(1)
vault_check() {
  _vault_require_tools || return

  printf 'Vault address: %s\n' "$VAULT_ADDR"
  vault status
}

## @category HashiCorp Vault
## @description Authenticate with Vault using OIDC method
## @usage vault_oidc_login [role]
## @arg $1 string Optional OIDC role name (defaults to VAULT_OIDC_ROLE)
## @requires vault
## @see vault-login(1)
vault_oidc_login() {
  _vault_require_command vault || return
  _vault_oidc_selected_role=${1:-$VAULT_OIDC_ROLE}
  vault login -method=oidc role="$_vault_oidc_selected_role"
  _vault_oidc_status=$?
  unset _vault_oidc_selected_role
  return "$_vault_oidc_status"
}

## @category HashiCorp Vault
## @description Authenticate with Vault using AppRole method
## @usage vault_approle_login
## @env VAULT_ROLE_ID Role ID for AppRole authentication (alternative to VAULT_ROLE_ID_FILE)
## @env VAULT_ROLE_ID_FILE File containing Role ID for AppRole authentication (alternative to VAULT_ROLE_ID)
## @env VAULT_SECRET_ID Secret ID for AppRole authentication (alternative to VAULT_SECRET_ID_FILE)
## @env VAULT_SECRET_ID_FILE File containing Secret ID for AppRole authentication (alternative to VAULT_SECRET_ID)
## @requires vault
## @requires jq
## @requires base64
## @exitcode 0 If authentication is successful
## @exitcode 1 If authentication fails
## @exitcode 2 If credentials are not provided
## @stdout Success message with AppRole name
## @stderr Error messages for missing credentials or authentication failures
vault_approle_login() {
  _vault_require_tools || return

  _vault_role_id="$(_vault_read_credential VAULT_ROLE_ID VAULT_ROLE_ID_FILE)" || {
    _vault_error "set VAULT_ROLE_ID or VAULT_ROLE_ID_FILE"
    return 2
  }
  _vault_secret_id="$(_vault_read_credential VAULT_SECRET_ID VAULT_SECRET_ID_FILE)" || {
    unset _vault_role_id
    _vault_error "set VAULT_SECRET_ID or VAULT_SECRET_ID_FILE"
    return 2
  }

  _vault_login_json="$(
    vault write -format=json "auth/${VAULT_APPROLE_MOUNT}/login" \
      role_id="$_vault_role_id" \
      secret_id="$_vault_secret_id"
  )"
  _vault_login_status=$?

  unset _vault_role_id _vault_secret_id

  if [ "$_vault_login_status" -ne 0 ]; then
    unset _vault_login_json _vault_login_status
    return 1
  fi

  VAULT_TOKEN="$(printf '%s' "$_vault_login_json" | jq -er '.auth.client_token')"
  _vault_token_status=$?
  unset _vault_login_json _vault_login_status

  if [ "$_vault_token_status" -ne 0 ] || [ -z "$VAULT_TOKEN" ]; then
    unset VAULT_TOKEN _vault_token_status
    _vault_error "Vault did not return a client token"
    return 1
  fi

  export VAULT_TOKEN
  unset _vault_token_status
  vault token lookup >/dev/null || {
    unset VAULT_TOKEN
    _vault_error "Vault returned a token that could not be validated"
    return 1
  }

  printf 'Authenticated with AppRole %s\n' "$VAULT_APPROLE_NAME"
}

## @category HashiCorp Vault
## @description Prompt for AppRole credentials and authenticate with Vault
## @usage vault_approle_login_prompt
## @stdin Prompts for Role ID and Secret ID
## @requires vault
## @requires jq
## @requires base64
## @exitcode 0 If authentication is successful
## @exitcode 1 If authentication fails or input is cancelled
## @stdout Success message with AppRole name
## @stderr Error messages for authentication failures
vault_approle_login_prompt() {
  _vault_require_tools || return

  printf 'Role ID: ' >&2
  IFS= read -r _vault_prompt_role_id
  printf 'Secret ID: ' >&2
  stty -echo
  IFS= read -r _vault_prompt_secret_id
  _vault_prompt_status=$?
  stty echo
  printf '\n' >&2

  if [ "$_vault_prompt_status" -ne 0 ]; then
    unset _vault_prompt_role_id _vault_prompt_secret_id _vault_prompt_status
    return 1
  fi

  VAULT_ROLE_ID=$_vault_prompt_role_id
  VAULT_SECRET_ID=$_vault_prompt_secret_id
  export VAULT_ROLE_ID VAULT_SECRET_ID

  vault_approle_login
  _vault_prompt_status=$?

  unset VAULT_ROLE_ID VAULT_SECRET_ID
  unset _vault_prompt_role_id _vault_prompt_secret_id
  return "$_vault_prompt_status"
}

## @category HashiCorp Vault
## @description Clear Vault authentication token
## @usage vault_logout
## @requires vault
## @stdout Confirmation message
vault_logout() {
  _vault_require_command vault || return

  if [ -n "${VAULT_TOKEN:-}" ]; then
    vault token revoke -self >/dev/null 2>&1 || true
    unset VAULT_TOKEN
  else
    vault logout >/dev/null 2>&1 || true
  fi

  printf 'Vault token cleared\n'
}

## @category HashiCorp Vault
## @description Display current Vault token information
## @usage vault_whoami
## @requires vault
## @stdout Current token details
## @see vault-token(1)
vault_whoami() {
  _vault_require_command vault || return
  vault token lookup
}

## @category HashiCorp Vault
## @description Encrypt plaintext using Vault transit secret engine
## @usage vault_encrypt [key_name]
## @arg $1 string Optional transit key name (defaults to VAULT_TRANSIT_KEY)
## @stdin Plaintext to encrypt
## @requires vault
## @requires jq
## @requires base64
## @stdout Encrypted ciphertext
## @exitcode 0 If encryption is successful
## @exitcode 1 If encryption fails
## @exitcode 2 If no plaintext is provided
## @stderr Error messages for encryption failures
vault_encrypt() {
  _vault_require_tools || return
  _vault_encrypt_key=${1:-$VAULT_TRANSIT_KEY}
  _vault_plaintext="$(base64 | tr -d '\n')" || return

  if [ -z "$_vault_plaintext" ]; then
    _vault_error "no plaintext received on stdin"
    unset _vault_encrypt_key _vault_plaintext
    return 2
  fi

  vault write -format=json \
    "${VAULT_TRANSIT_MOUNT}/encrypt/${_vault_encrypt_key}" \
    plaintext="$_vault_plaintext" |
    jq -er '.data.ciphertext'
  _vault_encrypt_status=$?

  unset _vault_encrypt_key _vault_plaintext
  return "$_vault_encrypt_status"
}

## @category HashiCorp Vault
## @description Decrypt ciphertext using Vault transit secret engine
## @usage vault_decrypt [key_name]
## @arg $1 string Optional transit key name (defaults to VAULT_TRANSIT_KEY)
## @stdin Ciphertext to decrypt
## @requires vault
## @requires jq
## @requires base64
## @stdout Decrypted plaintext
## @exitcode 0 If decryption is successful
## @exitcode 1 If decryption fails
## @exitcode 2 If no ciphertext is provided
## @stderr Error messages for decryption failures
vault_decrypt() {
  _vault_require_tools || return
  _vault_decrypt_key=${1:-$VAULT_TRANSIT_KEY}
  IFS= read -r _vault_ciphertext

  if [ -z "$_vault_ciphertext" ]; then
    _vault_error "no ciphertext received on stdin"
    unset _vault_decrypt_key _vault_ciphertext
    return 2
  fi

  _vault_decrypted_base64="$(
    vault write -format=json \
      "${VAULT_TRANSIT_MOUNT}/decrypt/${_vault_decrypt_key}" \
      ciphertext="$_vault_ciphertext" |
      jq -er '.data.plaintext'
  )" || {
    unset _vault_decrypt_key _vault_ciphertext _vault_decrypted_base64
    return 1
  }

  printf '%s' "$_vault_decrypted_base64" | base64 --decode
  _vault_decrypt_status=$?

  unset _vault_decrypt_key _vault_ciphertext _vault_decrypted_base64
  return "$_vault_decrypt_status"
}

## @category HashiCorp Vault
## @description Encrypt a file using Vault transit secret engine
## @usage vault_encrypt_file <input_file> <output_file> [key_name]
## @arg $1 string Input file path to encrypt
## @arg $2 string Output file path for encrypted data
## @arg $3 string Optional transit key name (defaults to VAULT_TRANSIT_KEY)
## @requires vault
## @requires jq
## @requires base64
## @exitcode 0 If encryption is successful
## @exitcode 1 If encryption fails or input file is not readable
## @exitcode 2 If arguments are missing
## @stderr Error messages for file access or encryption failures
vault_encrypt_file() {
  _vault_input_file=${1:-}
  _vault_output_file=${2:-}
  _vault_file_key=${3:-$VAULT_TRANSIT_KEY}

  if [ -z "$_vault_input_file" ] || [ -z "$_vault_output_file" ]; then
    _vault_error "usage: vault_encrypt_file INPUT OUTPUT [KEY]"
    return 2
  fi
  if [ ! -f "$_vault_input_file" ] || [ ! -r "$_vault_input_file" ]; then
    _vault_error "input file is not readable: $_vault_input_file"
    return 1
  fi

  _vault_output_dir=$(dirname -- "$_vault_output_file")
  mkdir -p -- "$_vault_output_dir" || return
  _vault_temp_file=$(mktemp "${_vault_output_dir}/.vault-encrypted.XXXXXX") ||
    return

  if vault_encrypt "$_vault_file_key" <"$_vault_input_file" >"$_vault_temp_file"; then
    chmod 600 "$_vault_temp_file"
    mv -f -- "$_vault_temp_file" "$_vault_output_file"
    _vault_file_status=$?
  else
    _vault_file_status=$?
    rm -f -- "$_vault_temp_file"
  fi

  unset _vault_input_file _vault_output_file _vault_file_key
  unset _vault_output_dir _vault_temp_file
  return "$_vault_file_status"
}

## @category HashiCorp Vault
## @description Decrypt a file using Vault transit secret engine
## @usage vault_decrypt_file <input_file> <output_file> [key_name]
## @arg $1 string Input file path to decrypt
## @arg $2 string Output file path for decrypted data
## @arg $3 string Optional transit key name (defaults to VAULT_TRANSIT_KEY)
## @requires vault
## @requires jq
## @requires base64
## @exitcode 0 If decryption is successful
## @exitcode 1 If decryption fails or input file is not readable
## @exitcode 2 If arguments are missing
## @stderr Error messages for file access or decryption failures
vault_decrypt_file() {
  _vault_input_file=${1:-}
  _vault_output_file=${2:-}
  _vault_file_key=${3:-$VAULT_TRANSIT_KEY}

  if [ -z "$_vault_input_file" ] || [ -z "$_vault_output_file" ]; then
    _vault_error "usage: vault_decrypt_file INPUT OUTPUT [KEY]"
    return 2
  fi
  if [ ! -f "$_vault_input_file" ] || [ ! -r "$_vault_input_file" ]; then
    _vault_error "input file is not readable: $_vault_input_file"
    return 1
  fi

  _vault_output_dir=$(dirname -- "$_vault_output_file")
  mkdir -p -- "$_vault_output_dir" || return
  _vault_temp_file=$(mktemp "${_vault_output_dir}/.vault-decrypted.XXXXXX") ||
    return
  chmod 600 "$_vault_temp_file"

  if vault_decrypt "$_vault_file_key" <"$_vault_input_file" >"$_vault_temp_file"; then
    mv -f -- "$_vault_temp_file" "$_vault_output_file"
    _vault_file_status=$?
  else
    _vault_file_status=$?
    rm -f -- "$_vault_temp_file"
  fi

  unset _vault_input_file _vault_output_file _vault_file_key
  unset _vault_output_dir _vault_temp_file
  return "$_vault_file_status"
}

## @category HashiCorp Vault
## @description Get a key-value secret from Vault
## @usage vault_kv_get <path>
## @arg $1 string Path to the secret in Vault KV store
## @requires vault
## @stdout Secret data
## @exitcode 0 If secret is retrieved successfully
## @exitcode 2 If path argument is missing
## @stderr Error messages for retrieval failures
## @see vault-kv(1)
vault_kv_get() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_get PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv get -mount="$VAULT_KV_MOUNT" "$1"
}

## @category HashiCorp Vault
## @description Get a specific field from a key-value secret in Vault
## @usage vault_kv_get_field <path> <field>
## @arg $1 string Path to the secret in Vault KV store
## @arg $2 string Field name to retrieve
## @requires vault
## @stdout Field value
## @exitcode 0 If field is retrieved successfully
## @exitcode 2 If arguments are missing
## @stderr Error messages for retrieval failures
## @see vault-kv(1)
vault_kv_get_field() {
  [ "$#" -eq 2 ] || {
    _vault_error "usage: vault_kv_get_field PATH FIELD"
    return 2
  }
  _vault_require_command vault || return
  vault kv get -mount="$VAULT_KV_MOUNT" -field="$2" "$1"
}

## @category HashiCorp Vault
## @description Put a key-value secret into Vault
## @usage vault_kv_put <path> <key>=<value> [key=value...]
## @arg $1 string Path to store the secret in Vault KV store
## @arg $@ string Key-value pairs to store
## @requires vault
## @exitcode 0 If secret is stored successfully
## @exitcode 2 If arguments are missing
## @stderr Error messages for storage failures
## @see vault-kv(1)
vault_kv_put() {
  [ "$#" -ge 2 ] || {
    _vault_error "usage: vault_kv_put PATH KEY=VALUE [KEY=VALUE ...]"
    return 2
  }
  _vault_require_command vault || return

  _vault_kv_path=$1
  shift
  vault kv put -mount="$VAULT_KV_MOUNT" "$_vault_kv_path" "$@"
  _vault_kv_status=$?
  unset _vault_kv_path
  return "$_vault_kv_status"
}

## @category HashiCorp Vault
## @description Delete a key-value secret from Vault
## @usage vault_kv_delete <path>
## @arg $1 string Path to the secret in Vault KV store
## @requires vault
## @exitcode 0 If secret is deleted successfully
## @exitcode 2 If path argument is missing
## @stderr Error messages for deletion failures
## @see vault-kv(1)
vault_kv_delete() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_delete PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv delete -mount="$VAULT_KV_MOUNT" "$1"
}

## @category HashiCorp Vault
## @description List key-value secrets at a path in Vault
## @usage vault_kv_list <path>
## @arg $1 string Path to list secrets in Vault KV store
## @requires vault
## @stdout List of secrets
## @exitcode 0 If listing is successful
## @exitcode 2 If path argument is missing
## @stderr Error messages for listing failures
## @see vault-kv(1)
vault_kv_list() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_list PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv list -mount="$VAULT_KV_MOUNT" "$1"
}

## @category HashiCorp Vault
## @description Unwrap a Vault wrapping token
## @usage vault_unwrap
## @stdin Prompts for wrapping token
## @requires vault
## @stdout Unwrapped secret data
## @exitcode 0 If unwrapping is successful
## @exitcode 1 If unwrapping fails or input is cancelled
## @stderr Error messages for unwrapping failures
vault_unwrap() {
  _vault_require_command vault || return

  printf 'Wrapping token: ' >&2
  stty -echo
  IFS= read -r _vault_wrapping_token
  _vault_unwrap_status=$?
  stty echo
  printf '\n' >&2

  if [ "$_vault_unwrap_status" -ne 0 ]; then
    unset _vault_wrapping_token _vault_unwrap_status
    return 1
  fi

  VAULT_TOKEN=$_vault_wrapping_token vault unwrap
  _vault_unwrap_status=$?
  unset _vault_wrapping_token
  return "$_vault_unwrap_status"
}
