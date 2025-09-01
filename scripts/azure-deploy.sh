#!/usr/bin/env bash
set -euo pipefail

# One-click Azure deploy for CIA stack
# - Provisions Azure VM via Terraform
# - Generates .env with sslip.io hosts and ACME email
# - Copies the repo to the VM
# - Starts Traefik (with Let's Encrypt) + App via Docker Compose

ACME_EMAIL="${1:-oscar.robert-besle@epitech.eu}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform/azure-vm"
REMOTE_USER="azureuser"
REMOTE_PATH="/opt/cia"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform not found in PATH" >&2
  exit 1
fi
if command -v az >/dev/null 2>&1; then
  if ! az account show >/dev/null 2>&1; then
    echo "INFO: Azure CLI not logged in. Run: az login && optionally az account set --subscription <SUB_ID>" >&2
  fi
fi

# Ensure Terraform sees current subscription via env if possible
if command -v az >/dev/null 2>&1; then
  SUB_ID="$(az account show --query id -o tsv 2>/dev/null || true)"
  TENANT_ID="$(az account show --query tenantId -o tsv 2>/dev/null || true)"
  if [[ -n "$SUB_ID" ]]; then
    export ARM_SUBSCRIPTION_ID="$SUB_ID"
    echo "Using Azure subscription: $SUB_ID"
  fi
  if [[ -n "$TENANT_ID" ]]; then
    export ARM_TENANT_ID="$TENANT_ID"
  fi
fi

echo "[1/6] Terraform init/apply in $TF_DIR"
terraform -chdir="$TF_DIR" init -upgrade -input=false
terraform -chdir="$TF_DIR" apply -auto-approve -input=false

IP=$(terraform -chdir="$TF_DIR" output -raw public_ip)
if [[ -z "$IP" ]]; then
  echo "ERROR: Could not fetch public_ip from Terraform outputs" >&2
  exit 1
fi
echo "VM Public IP: $IP"

SSH_CMD="ssh -o StrictHostKeyChecking=accept-new ${REMOTE_USER}@${IP}"
SCP_CMD="scp -o StrictHostKeyChecking=accept-new"

echo "[2/6] Generate .env from .env.azure.example (ACME_EMAIL=$ACME_EMAIL)"
IP_DASH=${IP//./-}
ENV_SRC="$ROOT_DIR/.env.azure.example"
ENV_TMP="$ROOT_DIR/.env.azure.generated"
if [[ ! -f "$ENV_SRC" ]]; then
  echo "ERROR: Template $ENV_SRC not found" >&2
  exit 1
fi
sed "s/<IP_DASH>/$IP_DASH/g" "$ENV_SRC" | \
  awk -v email="$ACME_EMAIL" 'BEGIN{e=email} /^ACME_EMAIL=/{$0="ACME_EMAIL=" e} {print}' > "$ENV_TMP"

echo "[3/6] Copy repo to VM ($REMOTE_PATH)"
$SSH_CMD "sudo mkdir -p $REMOTE_PATH && sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_PATH"

# Use tar-over-ssh to copy working tree excluding heavy/irrelevant files
EXCLUDES=(
  --exclude='.git'
  --exclude='node_modules'
  --exclude='**/dist'
  --exclude='**/.DS_Store'
  --exclude='infra/terraform/**/.terraform'
  --exclude='infra/terraform/**/terraform.tfstate*'
)
tar czf - "${EXCLUDES[@]}" -C "$ROOT_DIR" . | $SSH_CMD "tar xzf - -C $REMOTE_PATH"

echo "[4/6] Upload .env to VM"
$SCP_CMD "$ENV_TMP" ${REMOTE_USER}@${IP}:$REMOTE_PATH/.env

echo "[5/6] Wait for Docker on VM and start services"
$SSH_CMD "bash -lc 'i=0; until command -v docker >/dev/null 2>&1 || [ \$i -gt 60 ]; do i=\$((i+1)); sleep 2; done; command -v docker || exit 1'"

# Start ops (Traefik + Grafana + Portainer + Gitea)
$SSH_CMD "bash -lc 'sudo docker network create traefik || true'"
$SSH_CMD "bash -lc 'cd $REMOTE_PATH && sudo docker compose -f ops/docker-compose.yml -f ops/docker-compose.azure.yml up -d'"

# Build + start app
$SSH_CMD "bash -lc 'cd $REMOTE_PATH && sudo docker compose -f app/docker-compose.yml -f app/docker-compose.azure.yml build'"
$SSH_CMD "bash -lc 'cd $REMOTE_PATH && sudo docker compose -f app/docker-compose.yml -f app/docker-compose.azure.yml up -d'"

echo "[6/6] Done. Access your services shortly after certificates are issued:"
echo "  Frontend : https://app.$IP_DASH.sslip.io"
echo "  API      : https://api.$IP_DASH.sslip.io"
echo "  Grafana  : https://grafana.$IP_DASH.sslip.io"
echo "  Portainer: https://portainer.$IP_DASH.sslip.io"
echo "  Gitea    : https://gitea.$IP_DASH.sslip.io (SSH: ssh -p 2222 git@$IP)"
echo "  Traefik  : https://traefik.$IP_DASH.sslip.io (default admin/admin — change ops/traefik/dynamic/.htpasswd)"

echo "Tip: To redeploy after code changes, rerun steps [3/6]–[5/6] (copy + compose)."
