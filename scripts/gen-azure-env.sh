#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/gen-azure-env.sh [ACME_EMAIL]
# Generates .env with sslip.io hosts from Terraform output public_ip

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform/azure-vm"
EMAIL="${1:-oscar.robert-besle@epitech.eu}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi

IP=$(terraform -chdir="$TF_DIR" output -raw public_ip)
if [[ -z "$IP" ]]; then
  echo "Could not fetch public_ip from Terraform outputs" >&2
  exit 1
fi

IP_DASH=${IP//./-}
SRC="$ROOT_DIR/.env.azure.example"
DST="$ROOT_DIR/.env"

if [[ ! -f "$SRC" ]]; then
  echo "Template $SRC not found" >&2
  exit 1
fi

sed "s/<IP_DASH>/$IP_DASH/g" "$SRC" | \
  awk -v email="$EMAIL" 'BEGIN{e=email} /^ACME_EMAIL=/{$0="ACME_EMAIL=" e} {print}' > "$DST"

echo "Generated $DST using IP $IP (sslip.io hosts) and ACME_EMAIL=$EMAIL"

