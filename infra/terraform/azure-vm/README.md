**Azure VM (Docker) Deployment**

- Purpose: Provision a single Ubuntu VM in Azure, install Docker, and run your stack with Docker Compose.
- Fit: Easiest path to run your existing Traefik + Compose setup without converting to AKS.

**What You Get**
- Resource group, VNet/Subnet, NSG, Static public IP
- Ubuntu 22.04 VM with Docker Engine + Compose plugin + Git + Make
- Cloud-init prepares the host; you can optionally auto-clone the repo

**Prerequisites**
- Azure subscription + `az login`
- Terraform >= 1.5
- An SSH public key (e.g., `~/.ssh/id_rsa.pub`)

**Quick Start**
- Create `terraform.tfvars` (or use the provided tailored one):
  - `project = "cia"`
  - `location = "westeurope"`
  - `admin_username = "azureuser"`
  - `ssh_public_key_path = "~/.ssh/id_rsa.pub"`
  - `allowed_ssh_cidrs = ["YOUR_IP/32"]`  # Avoid 0.0.0.0/0
  - Optional: `git_repo_url = "https://github.com/your-org/rattrapage_CIA.git"`
  - Optional: `git_repo_branch = "main"`

Commands:
- `terraform init`
- `terraform apply -auto-approve`

Outputs:
- `public_ip`: public IP of the VM
- `ssh`: SSH command suggestion
- `suggested_hosts`: ready-to-use `sslip.io` hostnames for Traefik

**Deploy the stack on the VM**
- One-click end-to-end from repo root:
  - `bash scripts/azure-deploy.sh your-acme-email@example.com`
  - This will: apply Terraform, generate `.env` with sslip.io hosts, copy the repo to the VM, and start all services.

- SSH to the VM: run the `ssh` output
- If you didn’t auto-clone, place the repo at `/opt/cia` or clone:
  - `sudo mkdir -p /opt && sudo chown "$USER" /opt`
  - `git clone <repo_url> /opt/cia && cd /opt/cia`

- Pick hostnames for Traefik (choose one):
  - Use your own DNS (recommended): create DNS A records pointing to the VM IP:
    - `app.example.com`, `api.example.com`, `grafana.example.com`, `portainer.example.com`, `gitea.example.com`, `traefik.example.com`
  - Or use `sslip.io` quickly (no DNS management):
    - If IP is `x.y.z.w`: `app.x-y-z-w.sslip.io`, `api.x-y-z-w.sslip.io`, etc.

- Configure env for Azure routing (one-time):
  - Copy `.env.azure.example` to `.env` (or merge values into your existing `.env`):
    - Set `APP_HOST`, `API_HOST`, `GRAFANA_HOST`, `PORTAINER_HOST`, `GITEA_HOST`, `TRAEFIK_HOST`

- Start services (Traefik first, then app) with Azure overrides:
  - `docker network create traefik || true`
  - `docker compose -f ops/docker-compose.yml -f ops/docker-compose.azure.yml up -d`
  - `docker compose -f app/docker-compose.yml -f app/docker-compose.azure.yml build`
  - `docker compose -f app/docker-compose.yml -f app/docker-compose.azure.yml up -d`

Access:
- Frontend: `https://$APP_HOST`
- API: `https://$API_HOST`
- Grafana: `https://$GRAFANA_HOST`
- Portainer: `https://$PORTAINER_HOST`
- Gitea: `https://$GITEA_HOST` (SSH: `$GITEA_SSH_PORT` on the VM public IP)
- Traefik dashboard: `https://$TRAEFIK_HOST`

**Notes & Hardening**
- NSG allows 80/443 from anywhere; SSH and Gitea SSH can be IP-restricted via `allowed_ssh_cidrs` and `allowed_gitea_ssh_cidrs`.
- Database ports are not exposed publicly.
- For trusted TLS, configure Traefik with ACME/Let’s Encrypt and real domains (see `ops/traefik/`); self-signed is fine for tests.
- Consider a data disk or Azure File for persistent volumes in production.
