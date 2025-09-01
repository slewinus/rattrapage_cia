#!/bin/bash

# Security services initialization script
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}      Initializing Security Services (Vault & Fail2ban)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

# Check if running with appropriate permissions
if [ "$EUID" -ne 0 ] && [ -z "$DOCKER_HOST" ]; then 
    echo -e "${YELLOW}!  Note: You might need sudo for Fail2ban network operations${NC}"
fi

# Create necessary directories
echo -e "${YELLOW} Creating directories...${NC}"
mkdir -p ops/vault/{config,logs,data,scripts,policies}
mkdir -p ops/fail2ban/{filter.d,action.d}
mkdir -p /tmp/vault-keys

# Make scripts executable
chmod +x ops/vault/scripts/*.sh 2>/dev/null || true

# Start security services
echo -e "${YELLOW} Starting security services...${NC}"
docker compose -f ops/security-compose.yml up -d

# Wait for Vault to be ready
echo -e "${YELLOW} Waiting for Vault to start...${NC}"
sleep 10

# Initialize Vault
echo -e "${YELLOW} Initializing Vault...${NC}"
docker compose -f ops/security-compose.yml exec -T vault sh -c '
    if [ ! -f /vault/config/vault-initialized ]; then
        vault operator init -key-shares=5 -key-threshold=3 -format=json > /tmp/vault-init.json
        
        # Extract keys and token
        cat /tmp/vault-init.json | jq -r ".unseal_keys_b64[]" > /tmp/unseal-keys.txt
        cat /tmp/vault-init.json | jq -r ".root_token" > /tmp/root-token.txt
        
        # Auto-unseal (for development - DO NOT use in production!)
        for key in $(head -3 /tmp/unseal-keys.txt); do
            vault operator unseal $key
        done
        
        touch /vault/config/vault-initialized
        
        echo " Vault initialized and unsealed"
        echo "Root Token: $(cat /tmp/root-token.txt)"
        echo "Unseal Keys saved in container at /tmp/unseal-keys.txt"
    else
        echo " Vault already initialized"
    fi
'

# Copy initialization output to host
echo -e "${YELLOW} Retrieving Vault credentials...${NC}"
docker compose -f ops/security-compose.yml exec -T vault sh -c 'cat /tmp/root-token.txt 2>/dev/null || echo "Token not found"' > /tmp/vault-keys/root-token.txt
docker compose -f ops/security-compose.yml exec -T vault sh -c 'cat /tmp/unseal-keys.txt 2>/dev/null || echo "Keys not found"' > /tmp/vault-keys/unseal-keys.txt

# Display Vault access info
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} Security Services Initialized!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW} Vault Access:${NC}"
echo -e "   URL: ${GREEN}https://vault.localhost:8443${NC}"
echo -e "   UI:  ${GREEN}https://vault-ui.localhost:8443${NC}"
echo -e "   Root Token: ${GREEN}$(cat /tmp/vault-keys/root-token.txt 2>/dev/null || echo 'Check /tmp/vault-keys/root-token.txt')${NC}"
echo ""
echo -e "${YELLOW}  Fail2ban Status:${NC}"
docker compose -f ops/security-compose.yml exec -T fail2ban fail2ban-client status 2>/dev/null || echo "   Fail2ban is starting..."
echo ""
echo -e "${YELLOW}!  Important:${NC}"
echo -e "   1. Save the root token and unseal keys securely!"
echo -e "   2. Keys are temporarily stored in: /tmp/vault-keys/"
echo -e "   3. Configure your apps to use Vault for secrets"
echo -e "   4. Fail2ban is monitoring all services for brute force attacks"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"