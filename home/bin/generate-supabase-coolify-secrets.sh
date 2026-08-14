#!/usr/bin/env bash
set -Eeuo pipefail

OUTPUT_FILE="${OUTPUT_FILE:-./supabase-coolify.env}"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }

for cmd in git openssl jq sed grep mktemp; do
  require_cmd "$cmd"
done

umask 077
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

printf 'Fetching current Supabase self-hosting utilities...\n'

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/supabase/supabase.git \
  "$TMP_DIR/supabase" >/dev/null 2>&1

cd "$TMP_DIR/supabase"
git sparse-checkout set docker

DOCKER_DIR="$TMP_DIR/supabase/docker"
[[ -d "$DOCKER_DIR" ]] || die "Supabase docker directory was not found."
cd "$DOCKER_DIR"

cp .env.example .env

printf 'Generating Supabase secrets and legacy JWT keys...\n'
sh utils/generate-keys.sh >/dev/null

printf 'Generating modern publishable/secret keys...\n'
sh utils/add-new-auth-keys.sh >/dev/null

read_env() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" .env | tail -n 1 || true)"
  [[ -n "$line" ]] || return 1
  printf '%s' "${line#*=}"
}

required_env() {
  local key="$1"
  local value
  value="$(read_env "$key" || true)"
  [[ -n "$value" ]] || die "Supabase generator did not produce $key"
  printf '%s' "$value"
}

optional_env() {
  local key="$1"
  read_env "$key" || true
}

POSTGRES_PASSWORD="$(required_env POSTGRES_PASSWORD)"
JWT_SECRET="$(required_env JWT_SECRET)"
ANON_KEY="$(required_env ANON_KEY)"
SERVICE_ROLE_KEY="$(required_env SERVICE_ROLE_KEY)"
DASHBOARD_USERNAME="$(optional_env DASHBOARD_USERNAME)"
DASHBOARD_PASSWORD="$(required_env DASHBOARD_PASSWORD)"
SECRET_KEY_BASE="$(required_env SECRET_KEY_BASE)"
VAULT_ENC_KEY="$(required_env VAULT_ENC_KEY)"
PG_META_CRYPTO_KEY="$(required_env PG_META_CRYPTO_KEY)"
LOGFLARE_PUBLIC_ACCESS_TOKEN="$(required_env LOGFLARE_PUBLIC_ACCESS_TOKEN)"
LOGFLARE_PRIVATE_ACCESS_TOKEN="$(required_env LOGFLARE_PRIVATE_ACCESS_TOKEN)"

SUPABASE_PUBLISHABLE_KEY="$(optional_env SUPABASE_PUBLISHABLE_KEY)"
SUPABASE_SECRET_KEY="$(optional_env SUPABASE_SECRET_KEY)"
ANON_KEY_ASYMMETRIC="$(optional_env ANON_KEY_ASYMMETRIC)"
SERVICE_ROLE_KEY_ASYMMETRIC="$(optional_env SERVICE_ROLE_KEY_ASYMMETRIC)"
REALTIME_DB_ENC_KEY="$(optional_env REALTIME_DB_ENC_KEY)"
S3_PROTOCOL_ACCESS_KEY_ID="$(optional_env S3_PROTOCOL_ACCESS_KEY_ID)"
S3_PROTOCOL_ACCESS_KEY_SECRET="$(optional_env S3_PROTOCOL_ACCESS_KEY_SECRET)"
MINIO_ROOT_PASSWORD="$(optional_env MINIO_ROOT_PASSWORD)"

cat > "$OUTPUT_FILE" <<EOF
# Supabase / Coolify generated secrets
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# DO NOT COMMIT THIS FILE.

SERVICE_PASSWORD_POSTGRES=${POSTGRES_PASSWORD}

SERVICE_PASSWORD_JWT=${JWT_SECRET}
SERVICE_SUPABASEANON_KEY=${ANON_KEY}
SERVICE_SUPABASESERVICE_KEY=${SERVICE_ROLE_KEY}

SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}
SUPABASE_SECRET_KEY=${SUPABASE_SECRET_KEY}

ANON_KEY_ASYMMETRIC=${ANON_KEY_ASYMMETRIC}
SERVICE_ROLE_KEY_ASYMMETRIC=${SERVICE_ROLE_KEY_ASYMMETRIC}

SERVICE_USER_ADMIN=${DASHBOARD_USERNAME:-supabase}
SERVICE_PASSWORD_ADMIN=${DASHBOARD_PASSWORD}

SERVICE_PASSWORD_SUPAVISORSECRET=${SECRET_KEY_BASE}
SERVICE_PASSWORD_VAULTENC=${VAULT_ENC_KEY}
SERVICE_PASSWORD_PGMETACRYPTO=${PG_META_CRYPTO_KEY}

SERVICE_PASSWORD_LOGFLARE=${LOGFLARE_PUBLIC_ACCESS_TOKEN}
SERVICE_PASSWORD_LOGFLAREPRIVATE=${LOGFLARE_PRIVATE_ACCESS_TOKEN}

REALTIME_DB_ENC_KEY=${REALTIME_DB_ENC_KEY}
S3_PROTOCOL_ACCESS_KEY_ID=${S3_PROTOCOL_ACCESS_KEY_ID}
S3_PROTOCOL_ACCESS_KEY_SECRET=${S3_PROTOCOL_ACCESS_KEY_SECRET}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

POSTGRES_DB=postgres
POSTGRES_PORT=5432
JWT_EXPIRY=3600

STUDIO_DEFAULT_ORGANIZATION=OpenClaw
STUDIO_DEFAULT_PROJECT=OpenClaw Control Plane

POOLER_TENANT_ID=openclaw
POOLER_DEFAULT_POOL_SIZE=20
POOLER_MAX_CLIENT_CONN=100
POOLER_DB_POOL_SIZE=5

FUNCTIONS_VERIFY_JWT=false

DISABLE_SIGNUP=true
ENABLE_EMAIL_SIGNUP=false
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_PHONE_SIGNUP=false
ENABLE_PHONE_AUTOCONFIRM=false

# Set these if Coolify does not provide them:
# API_EXTERNAL_URL=https://supabase.example.ts.net
# GOTRUE_SITE_URL=https://your-frontend.example.ts.net
# ADDITIONAL_REDIRECT_URLS=https://your-frontend.example.ts.net/**
EOF

chmod 600 "$OUTPUT_FILE"

printf '\nGenerated: %s\n' "$OUTPUT_FILE"
printf 'Import the variables into Coolify. Keep secret/service-role values server-side only.\n'
