#!/bin/bash

# Script to populate initial secrets in Vault
set -e

VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"

echo " Populating secrets in Vault..."

# Check if VAULT_TOKEN is set
if [ -z "$VAULT_TOKEN" ]; then
    echo " Error: VAULT_TOKEN environment variable is not set"
    echo "   Run: export VAULT_TOKEN=<your-root-token>"
    exit 1
fi

# Enable KV v2 secrets engine
echo " Enabling KV v2 secrets engine..."
curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/sys/mounts/secret" \
    -d '{"type": "kv", "options": {"version": "2"}}' || echo "Secret engine might already be enabled"

# Store database credentials
echo " Storing database credentials..."
curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/database/mysql" \
    -d '{
        "data": {
            "username": "root",
            "password": "SecurePassword123!",
            "host": "db",
            "port": "3306",
            "database": "cia_database"
        }
    }'

# Store JWT secret
echo " Storing JWT secret..."
curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/app/jwt" \
    -d '{
        "data": {
            "secret": "your-super-secret-jwt-key-change-me-in-production"
        }
    }'

# Store API keys
echo " Storing API keys..."
curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/api-keys/external" \
    -d '{
        "data": {
            "grafana_api_key": "grafana-api-key-here",
            "gitea_api_key": "gitea-api-key-here"
        }
    }'

# Store monitoring credentials
echo " Storing monitoring credentials..."
curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/secret/data/monitoring/grafana" \
    -d '{
        "data": {
            "admin_user": "admin",
            "admin_password": "GrafanaAdmin2025!"
        }
    }'

# Create app policy
echo " Creating app policy..."
curl -s -X PUT \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/sys/policies/acl/app-policy" \
    -d '{
        "policy": "path \"secret/data/app/*\" {\n  capabilities = [\"read\", \"list\"]\n}\n\npath \"secret/data/database/*\" {\n  capabilities = [\"read\"]\n}\n\npath \"auth/token/renew-self\" {\n  capabilities = [\"update\"]\n}"
    }'

# Create an app token
echo " Creating app token..."
APP_TOKEN_RESPONSE=$(curl -s -X POST \
    -H "X-Vault-Token: ${VAULT_TOKEN}" \
    "${VAULT_ADDR}/v1/auth/token/create" \
    -d '{
        "policies": ["app-policy"],
        "ttl": "720h",
        "renewable": true
    }')

APP_TOKEN=$(echo "$APP_TOKEN_RESPONSE" | jq -r '.auth.client_token')

echo ""
echo " Secrets populated successfully!"
echo ""
echo " App Token: $APP_TOKEN"
echo "   Use this token for your application to access secrets"
echo ""
echo " Test reading a secret:"
echo "   curl -H \"X-Vault-Token: $APP_TOKEN\" ${VAULT_ADDR}/v1/secret/data/database/mysql"