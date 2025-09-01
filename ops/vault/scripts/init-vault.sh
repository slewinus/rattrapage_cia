#!/bin/bash

# Vault initialization script
set -e

VAULT_ADDR="http://localhost:8200"
VAULT_KEYS_FILE="/vault/config/vault-keys.json"

echo " Initializing HashiCorp Vault..."

# Wait for Vault to be ready
until curl -s "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; do
    echo " Waiting for Vault to be ready..."
    sleep 2
done

# Check if Vault is already initialized
if curl -s "${VAULT_ADDR}/v1/sys/init" | grep -q '"initialized":true'; then
    echo " Vault is already initialized"
else
    echo " Initializing Vault..."
    
    # Initialize Vault with 5 key shares and 3 threshold
    INIT_OUTPUT=$(curl -s -X PUT \
        "${VAULT_ADDR}/v1/sys/init" \
        -H "Content-Type: application/json" \
        -d '{"secret_shares": 5, "secret_threshold": 3}')
    
    # Save the keys securely
    echo "$INIT_OUTPUT" > "${VAULT_KEYS_FILE}"
    chmod 600 "${VAULT_KEYS_FILE}"
    
    echo "!  IMPORTANT: Vault keys saved to ${VAULT_KEYS_FILE}"
    echo "!  Keep these keys secure! You need at least 3 to unseal Vault."
    
    # Extract root token and unseal keys
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
    
    # Auto-unseal with first 3 keys (for development only!)
    echo " Unsealing Vault..."
    for i in 0 1 2; do
        KEY=$(echo "$INIT_OUTPUT" | jq -r ".keys[$i]")
        curl -s -X PUT \
            "${VAULT_ADDR}/v1/sys/unseal" \
            -H "Content-Type: application/json" \
            -d "{\"key\": \"$KEY\"}" > /dev/null
    done
    
    echo " Vault initialized and unsealed"
    echo ""
    echo " Root Token: $ROOT_TOKEN"
    echo "   Save this token securely!"
fi