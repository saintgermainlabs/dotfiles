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

_vault_error() {
  printf 'vault-helper: %s\n' "$*" >&2
}

_vault_require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    _vault_error "required command not found: $1"
    return 127
  }
}

_vault_require_tools() {
  _vault_require_command vault &&
    _vault_require_command jq &&
    _vault_require_command base64
}

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

vault_check() {
  _vault_require_tools || return

  printf 'Vault address: %s\n' "$VAULT_ADDR"
  vault status
}

vault_oidc_login() {
  _vault_require_command vault || return
  _vault_oidc_selected_role=${1:-$VAULT_OIDC_ROLE}
  vault login -method=oidc role="$_vault_oidc_selected_role"
  _vault_oidc_status=$?
  unset _vault_oidc_selected_role
  return "$_vault_oidc_status"
}

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

vault_whoami() {
  _vault_require_command vault || return
  vault token lookup
}

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

vault_kv_get() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_get PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv get -mount="$VAULT_KV_MOUNT" "$1"
}

vault_kv_get_field() {
  [ "$#" -eq 2 ] || {
    _vault_error "usage: vault_kv_get_field PATH FIELD"
    return 2
  }
  _vault_require_command vault || return
  vault kv get -mount="$VAULT_KV_MOUNT" -field="$2" "$1"
}

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

vault_kv_delete() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_delete PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv delete -mount="$VAULT_KV_MOUNT" "$1"
}

vault_kv_list() {
  [ "$#" -eq 1 ] || {
    _vault_error "usage: vault_kv_list PATH"
    return 2
  }
  _vault_require_command vault || return
  vault kv list -mount="$VAULT_KV_MOUNT" "$1"
}

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

