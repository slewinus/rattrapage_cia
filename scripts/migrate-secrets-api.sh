#!/bin/bash

# Migration des secrets vers Vault via API
set -e

# Configuration
VAULT_ADDR="http://localhost:8201"
VAULT_TOKEN="myroot"

echo " Migration des secrets vers HashiCorp Vault..."
echo "================================================"

# Fonction pour stocker un secret
store_secret() {
    local path=$1
    local data=$2
    
    curl -s -X POST \
        -H "X-Vault-Token: $VAULT_TOKEN" \
        "$VAULT_ADDR/v1/secret/data/$path" \
        -d "$data" > /dev/null
    
    echo "  ✓ Secret stocké: $path"
}

# 1. DATABASE SECRETS
echo ""
echo " Migration des secrets de base de données..."
store_secret "database/mysql" '{
    "data": {
        "host": "db",
        "port": "3306",
        "username": "root",
        "password": "SecurePassword123!",
        "database": "cia_database",
        "root_password": "SecurePassword123!"
    }
}'

# 2. API SECRETS
echo " Migration des secrets API..."
store_secret "api/config" '{
    "data": {
        "jwt_secret": "your-super-secret-jwt-key-change-me-in-production",
        "node_env": "production",
        "api_port": "3000",
        "api_host": "0.0.0.0",
        "python": "/usr/bin/python3"
    }
}'

# 3. MONITORING SECRETS
echo " Migration des secrets de monitoring..."
store_secret "monitoring/grafana" '{
    "data": {
        "admin_user": "admin",
        "admin_password": "GrafanaAdmin2025!"
    }
}'

store_secret "monitoring/portainer" '{
    "data": {
        "admin_password": "PortainerAdmin2025!"
    }
}'

# 4. GITEA SECRETS
echo " Migration des secrets Gitea..."
store_secret "gitea/config" '{
    "data": {
        "admin_user": "gitea_admin",
        "admin_password": "GiteaAdmin2025!",
        "admin_email": "admin@gitea.local",
        "db_password": "GiteaPassword123!"
    }
}'

echo ""
echo " Secrets migrés avec succès !"
echo ""
echo "📖 Pour vérifier les secrets :"
echo "  curl -H \"X-Vault-Token: $VAULT_TOKEN\" $VAULT_ADDR/v1/secret/data/database/mysql | jq"
