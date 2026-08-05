set -euo pipefail

KEY_PATH=/home/god/.ssh/knowledge-library-deploy-key
VAULT_KEY_PATH=secret/openclaw/github/knowledge-library

install -d -m 700 /home/god/.ssh

# Remove only the previous empty deploy-key files.
rm -f -- "$KEY_PATH" "$KEY_PATH.pub"

# Generate a new Ed25519 deploy key.
ssh-keygen \
  -t ed25519 \
  -C 'openclaw-knowledge-library' \
  -N '' \
  -f "$KEY_PATH"

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# Refuse to continue if either file is empty.
test -s "$KEY_PATH"
test -s "$KEY_PATH.pub"

echo "Private key size: $(wc -c < "$KEY_PATH") bytes"
echo "Public key size:  $(wc -c < "$KEY_PATH.pub") bytes"

# Show the public fingerprint, not the private key.
ssh-keygen -lf "$KEY_PATH.pub"