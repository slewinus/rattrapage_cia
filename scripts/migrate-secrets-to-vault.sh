#!/bin/bash

# Migration des secrets vers Vault
set -e

# Configuration
VAULT_ADDR="http://localhost:8201"
VAULT_TOKEN="myroot"

echo " Migration des secrets vers HashiCorp Vault..."
echo "================================================"

# Export pour les commandes vault
export VAULT_ADDR
export VAULT_TOKEN

# Activation du moteur KV v2 si nécessaire
echo " Configuration du moteur de secrets..."
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "Secret engine déjà activé"

# 1. DATABASE SECRETS
echo ""
echo " Migration des secrets de base de données..."
vault kv put secret/database/mysql \
  host="db" \
  port="3306" \
  username="root" \
  password="SecurePassword123!" \
  database="cia_database" \
  root_password="SecurePassword123!"

# 2. API SECRETS
echo " Migration des secrets API..."
vault kv put secret/api/config \
  jwt_secret="your-super-secret-jwt-key-change-me-in-production" \
  node_env="production" \
  api_port="3000" \
  api_host="0.0.0.0" \
  python="/usr/bin/python3"

# 3. MONITORING SECRETS
echo " Migration des secrets de monitoring..."
vault kv put secret/monitoring/grafana \
  admin_user="admin" \
  admin_password="GrafanaAdmin2025!"

vault kv put secret/monitoring/loki \
  url="http://host.docker.internal:3100/loki/api/v1/push" \
  retention_period="168h"

vault kv put secret/monitoring/portainer \
  admin_password="PortainerAdmin2025!"

# 4. GITEA SECRETS
echo " Migration des secrets Gitea..."
vault kv put secret/gitea/config \
  admin_user="gitea_admin" \
  admin_password="GiteaAdmin2025!" \
  admin_email="admin@gitea.local" \
  db_name="gitea" \
  db_user="gitea" \
  db_password="GiteaPassword123!" \
  db_root_password="GiteaRootPassword123!" \
  secret_key="changeme-secret-key-minimum-64-chars-aaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  internal_token="changeme-internal-token-minimum-64-chars-bbbbbbbbbbbbbbbbbbbbbbbb"

# 5. TRAEFIK CONFIGURATION
echo " Migration de la configuration Traefik..."
vault kv put secret/traefik/ports \
  http_port="8080" \
  https_port="8443"

# 6. CREATE APP POLICIES
echo ""
echo " Création des politiques d'accès..."

# Policy pour l'API backend
vault policy write api-policy - <<EOF
# Read database credentials
path "secret/data/database/*" {
  capabilities = ["read"]
}

# Read API configuration
path "secret/data/api/*" {
  capabilities = ["read"]
}

# Token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

# Policy pour les services de monitoring
vault policy write monitoring-policy - <<EOF
# Read monitoring credentials
path "secret/data/monitoring/*" {
  capabilities = ["read"]
}
EOF

# Policy pour Gitea
vault policy write gitea-policy - <<EOF
# Read Gitea configuration
path "secret/data/gitea/*" {
  capabilities = ["read"]
}
EOF

# 7. CREATE SERVICE TOKENS
echo ""
echo " Création des tokens pour les services..."

# Token pour l'API
API_TOKEN=$(vault token create -policy=api-policy -ttl=720h -format=json | jq -r '.auth.client_token')
echo "API Token: $API_TOKEN"

# Token pour monitoring
MONITORING_TOKEN=$(vault token create -policy=monitoring-policy -ttl=720h -format=json | jq -r '.auth.client_token')
echo "Monitoring Token: $MONITORING_TOKEN"

# Token pour Gitea
GITEA_TOKEN=$(vault token create -policy=gitea-policy -ttl=720h -format=json | jq -r '.auth.client_token')
echo "Gitea Token: $GITEA_TOKEN"

# 8. SAVE TOKENS
echo ""
echo " Sauvegarde des tokens..."
cat > vault-tokens.env <<EOL
# Tokens Vault pour les services
# NE PAS COMMITER CE FICHIER !
VAULT_ADDR=$VAULT_ADDR
VAULT_TOKEN_API=$API_TOKEN
VAULT_TOKEN_MONITORING=$MONITORING_TOKEN
VAULT_TOKEN_GITEA=$GITEA_TOKEN
EOL

echo ""
echo " Migration terminée !"
echo ""
echo " Résumé :"
echo "  - Tous les secrets ont été migrés vers Vault"
echo "  - Les politiques d'accès ont été créées"
echo "  - Les tokens de service ont été générés"
echo ""
echo " Structure des secrets dans Vault :"
vault kv list -format=json secret/ | jq -r '.[]' | while read path; do
  echo "  - secret/$path"
done
echo ""
echo " Les tokens ont été sauvegardés dans : vault-tokens.env"
echo "   !  IMPORTANT: Ne commitez pas ce fichier !"
echo ""
echo "Pour utiliser les secrets dans vos applications :"
echo "   1. Utilisez le token correspondant à votre service"
echo "   2. Récupérez les secrets avec l'API Vault"
echo "   3. Exemple: vault kv get secret/database/mysql"
