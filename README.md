# 🚀 CIA Application - Infrastructure Complète Cloud & DevOps

## 📋 Table des matières
- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Déploiement Local](#-déploiement-local)
- [Déploiement Cloud Azure](#-déploiement-cloud-azure)
- [Configuration Ansible](#-configuration-ansible)
- [Infrastructure Terraform](#-infrastructure-terraform)
- [Services & Accès](#-services--accès)
- [API Backend](#-api-backend)
- [Monitoring & Observabilité](#-monitoring--observabilité)
- [Commandes Utiles](#-commandes-utiles)
- [Dépannage](#-dépannage)

## 🎯 Vue d'ensemble

Stack applicative moderne avec déploiement automatisé sur Azure :

### Stack Technique
- **Frontend** : React TypeScript avec build optimisé Alpine
- **Backend** : Node.js Express + TypeORM + JWT Auth
- **Base de données** : MariaDB 10.6
- **Reverse Proxy** : Traefik v3.0 avec Let's Encrypt
- **Monitoring** : Grafana + Loki + Prometheus + Promtail
- **Gestion** : Portainer CE + Gitea
- **Infrastructure** : Terraform (Azure) + Ansible
- **Conteneurisation** : Docker Compose v2

### Fonctionnalités DevOps
- ✅ Infrastructure as Code (Terraform)
- ✅ Configuration Management (Ansible)
- ✅ HTTPS automatique (Let's Encrypt)
- ✅ Centralisation des logs (Loki)
- ✅ Métriques (Prometheus)
- ✅ Dashboards (Grafana)
- ✅ Git privé (Gitea)
- ✅ Gestion Docker UI (Portainer)

## 🏗️ Architecture

```
rattrapage_cia/
├── app/                        # Stack applicative
│   ├── back_student/           # API Backend Node.js
│   │   ├── src/
│   │   │   ├── controller/     # Contrôleurs REST
│   │   │   ├── entity/         # Entités TypeORM
│   │   │   ├── migration/      # Migrations DB
│   │   │   └── routes/         # Routes Express
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── front_student/          # Frontend React
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── docker-compose.yml     # Services app
│
├── ops/                        # Stack monitoring
│   ├── grafana/
│   │   └── provisioning/       # Datasources auto
│   ├── prometheus/
│   │   └── prometheus.yml     # Config métriques
│   ├── traefik/
│   │   ├── traefik.yml        # Config principale
│   │   └── dynamic/           # Routes dynamiques
│   ├── loki-config.yml
│   └── docker-compose.yml     # Services ops
│
├── terraform/                  # Infrastructure Azure
│   ├── main.tf                # Ressources Azure
│   ├── variables.tf           # Variables
│   ├── outputs.tf             # Outputs
│   └── terraform.tfvars.example
│
├── ansible/                    # Automatisation déploiement
│   ├── site.yml               # Playbook principal
│   ├── inventory/
│   │   └── hosts.ini
│   ├── group_vars/
│   │   └── cia.yml           # Variables globales
│   └── roles/
│       ├── common/            # Config de base
│       ├── docker/            # Installation Docker
│       └── deploy/            # Déploiement app
│
├── Makefile                   # Commandes simplifiées
└── .env                       # Configuration globale
```

## 🖥️ Déploiement Local

### Prérequis
- Docker 24.0+
- Docker Compose v2
- Make
- 8GB RAM minimum
- Ports 80, 443 libres

### Installation rapide

```bash
# 1. Cloner le repository
git clone <repository-url>
cd rattrapage_cia

# 2. Lancement rapide (build + start)
make quick-start

# OU étape par étape :
make build   # Build des images
make start   # Lance tous les services
```

### Accès local
- **App** : https://app.localhost
- **API** : https://api.localhost
- **Grafana** : https://grafana.localhost
- **Portainer** : https://portainer.localhost
- **Gitea** : https://gitea.localhost
- **Traefik** : https://traefik.localhost


## ☁️ Déploiement Cloud Azure

### Architecture Azure
- **Resource Group** : `cia-prod-rg`
- **Région** : West Europe
- **VM** : Standard_B2s (2 vCPUs, 4GB RAM)
- **OS** : Ubuntu 22.04 LTS
- **Disque** : 30GB Premium SSD
- **Network** : VNet avec subnet dédié
- **Sécurité** : NSG avec règles 22/80/443/2223
- **IP Publique** : Statique avec DNS sslip.io

### Déploiement complet en 2 commandes

```bash
# 1. Provisionner l'infrastructure Azure
make cloud-up

# 2. Déployer l'application
make cloud-deploy
```

### Étapes détaillées

#### 1. Configuration Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Éditer `terraform.tfvars` :
```hcl
# Obligatoire
subscription_id = "XXXX-XXXX-XXXX-XXXX"
admin_username  = "azureuser"

# Optionnel
location        = "westeurope"
vm_size        = "Standard_B2s"
environment    = "prod"

# Auto-deploy Ansible après Terraform
auto_deploy_apps = true
acme_email      = "your-email@domain.com"
```

#### 2. Provisionner l'infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Outputs attendus :
```
public_ip = "X.X.X.X"
ssh_command = "ssh azureuser@X.X.X.X"
app_urls = {
  app       = "https://app.X-X-X-X.sslip.io"
  api       = "https://api.X-X-X-X.sslip.io"
  grafana   = "https://grafana.X-X-X-X.sslip.io"
  portainer = "https://portainer.X-X-X-X.sslip.io"
  gitea     = "https://gitea.X-X-X-X.sslip.io"
  traefik   = "https://traefik.X-X-X-X.sslip.io"
}
```

## 🔧 Configuration Ansible

### Structure Ansible

```yaml
# ansible/site.yml - Playbook principal
- hosts: cia
  roles:
    - common    # Packages de base, UFW
    - docker    # Docker + Compose
    - deploy    # Déploiement app
```

### Variables importantes

```yaml
# ansible/group_vars/cia.yml
project_root: /srv/cia
base_domain: "{{ ansible_host }}.sslip.io"
acme_email: admin@example.com

# Versions
docker_compose_version: "2.29.2"
```

### Déploiement manuel Ansible

```bash
# Installation des dépendances
ansible-galaxy collection install -r ansible/requirements.yml

# Déploiement sur une IP spécifique
ansible-playbook -i "X.X.X.X," -u azureuser ansible/site.yml \
  -e acme_email=your-email@domain.com

# OU avec inventory file
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml
```

### Ce que fait Ansible

1. **Configuration système**
   - Met à jour les packages
   - Configure UFW (22, 80, 443, 2223)
   - Installe les outils de base

2. **Installation Docker**
   - Ajoute le repository Docker officiel
   - Installe Docker CE + Compose plugin
   - Configure l'utilisateur

3. **Déploiement application**
   - Synchronise le code vers `/srv/cia`
   - Configure les variables d'environnement
   - Build les images Docker
   - Lance les stacks ops et app
   - Configure Traefik + Let's Encrypt

## 🌐 Infrastructure Terraform

### Ressources créées

```hcl
# Resource Group
azurerm_resource_group "cia-prod-rg"

# Réseau
azurerm_virtual_network "cia-vnet" {
  address_space = ["10.0.0.0/16"]
}

azurerm_subnet "cia-subnet" {
  address_prefixes = ["10.0.1.0/24"]
}

# Sécurité
azurerm_network_security_group "cia-nsg" {
  rules = [
    SSH (22), HTTP (80), HTTPS (443), 
    Gitea SSH (2223), Metrics (9100)
  ]
}

# VM
azurerm_linux_virtual_machine "cia-vm" {
  size = "Standard_B2s"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
}

# IP Publique
azurerm_public_ip "cia-pip" {
  allocation_method = "Static"
  sku              = "Standard"
}
```

### Variables Terraform

| Variable | Description | Défaut |
|----------|-------------|--------|
| `subscription_id` | ID Azure Subscription | Required |
| `location` | Région Azure | westeurope |
| `resource_group_name` | Nom du RG | cia-${env}-rg |
| `vm_size` | Taille de la VM | Standard_B2s |
| `admin_username` | User SSH | azureuser |
| `environment` | Environnement | prod |

## 🔐 Services & Accès

### URLs de production

Remplacez `X.X.X.X` par votre IP publique Azure :

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application** | https://app.X-X-X-X.sslip.io | admin / admin |
| **API Backend** | https://api.X-X-X-X.sslip.io | Token JWT |
| **Grafana** | https://grafana.X-X-X-X.sslip.io | admin / GrafanaAdmin2025! |
| **Portainer** | https://portainer.X-X-X-X.sslip.io | admin / PortainerAdmin2025! |
| **Gitea** | https://gitea.X-X-X-X.sslip.io | gitea_admin / GiteaAdmin2025! |
| **Gitea SSH** | ssh://git@X-X-X-X.sslip.io:2223 | Clés SSH |

### Configuration des services

#### Traefik (Reverse Proxy)
- Auto-discovery Docker
- Let's Encrypt automatique
- Redirection HTTP → HTTPS
- Métriques Prometheus

#### Grafana (Monitoring)
- Datasource Loki préconfigurée
- Dashboards Docker
- Alerting disponible

#### Gitea (Git Server)
- Miroir de GitHub/GitLab
- CI/CD intégré
- Packages registry

## 💻 API Backend

### Architecture
- **Framework** : Express.js
- **ORM** : TypeORM
- **Auth** : JWT
- **Database** : MariaDB
- **Swagger** : Documentation auto

### Endpoints principaux

```typescript
POST   /auth/login       // Authentification
POST   /auth/register    // Inscription
GET    /auth/profile     // Profil utilisateur

GET    /users           // Liste des utilisateurs (ADMIN)
POST   /users           // Créer utilisateur
PUT    /users/:id       // Modifier utilisateur
DELETE /users/:id       // Supprimer utilisateur
```

### Configuration initiale DB

```bash
# Création du user admin (première fois seulement)
cd app/back_student
yarn
yarn run typeorm migration:create -n CreateAdminUser

# Éditer src/migration/[timestamp]-CreateAdminUser.ts
# Ajouter le code de création admin
```

### Variables d'environnement

```env
# Base de données
DB_HOST=db
DB_PORT=3306
DB_USER=root
DB_PASSWORD=SecurePassword123!
DB_NAME=cia_database

# API
NODE_ENV=production
API_PORT=3000
JWT_SECRET=your-super-secret-jwt-key

# Python (pour certains scripts)
PYTHON=/usr/bin/python3
```

## 📊 Monitoring & Observabilité

### Stack de monitoring

```yaml
Logs:       Loki + Promtail
Métriques:  Prometheus
Visualisation: Grafana
Traces:     Jaeger (optionnel)
```

### Requêtes Loki utiles

```logql
# Tous les logs Docker
{job="docker"}

# Logs API avec erreurs
{container_name="cia-app-api-1"} |= "error"

# Logs Frontend
{container_name="cia-app-web-1"}

# Logs Traefik access
{container_name="cia-ops-traefik-1"} | json

# Erreurs 5xx
{container_name="cia-ops-traefik-1"} | json | status >= 500
```

### Métriques Prometheus

- CPU/Memory par container
- Requêtes HTTP (latence, status)
- Santé des services
- Métriques custom API

## 🛠️ Commandes Utiles

### Commandes Make principales

```bash
# Gestion du cycle de vie
make start          # Lance tous les services
make stop           # Arrête tous les services  
make restart        # Redémarre tous les services
make status         # État des containers

# Build et maintenance
make build          # Rebuild les images
make clean          # Supprime containers + images
make db-reset       # Réinitialise la BDD

# Logs et debug
make logs           # Logs en temps réel
make logs-api       # Logs API uniquement
make logs-ops       # Logs monitoring

# Shells
make shell-api      # Shell dans container API
make shell-db       # Console MySQL
make shell-gitea    # Shell Gitea

# Cloud
make cloud-up       # Terraform apply
make cloud-deploy   # Ansible deploy
make cloud-destroy  # Terraform destroy
make cloud-ssh      # SSH vers la VM
```

### Commandes Docker utiles

```bash
# Voir tous les containers
docker ps -a

# Logs d'un service spécifique
docker logs -f cia-app-api-1

# Stats en temps réel
docker stats

# Nettoyer les ressources
docker system prune -a
```


## 🔧 Dépannage

### Problèmes courants

#### Ports déjà utilisés
```bash
# Identifier le processus
sudo lsof -i :80
sudo lsof -i :443

# Tuer le processus
sudo kill -9 <PID>
```

#### Containers qui ne démarrent pas
```bash
# Vérifier les logs
docker logs cia-app-api-1

# Recréer avec force
docker compose -f app/docker-compose.yml up -d --force-recreate
```

#### Problèmes de certificats Let's Encrypt
```bash
# Vérifier les logs Traefik
docker logs cia-ops-traefik-1 | grep -i acme

# Réinitialiser les certificats
docker volume rm cia-ops_letsencrypt
make restart
```


```

## 📝 Notes de sécurité

### À changer en production

1. **Mots de passe** dans `.env` et `terraform.tfvars`
2. **JWT_SECRET** : Générer une clé forte
3. **Certificats SSL** : Utiliser des certificats validés
4. **Firewall** : Restreindre les IPs sources
5. **Backup** : Mettre en place une stratégie

### Bonnes pratiques

- ✅ Utiliser des secrets Azure Key Vault
- ✅ Activer la 2FA sur Gitea/Portainer
- ✅ Monitorer les accès SSH
- ✅ Rotation régulière des credentials
- ✅ Backup automatisé des volumes

## 🚀 Quick Start Production

```bash
# 1. Clone + config
git clone <repo>
cd rattrapage_cia
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Éditer terraform.tfvars

# 2. Déploiement complet
make cloud-up      # Crée l'infra Azure (~5min)
make cloud-deploy  # Déploie l'app (~10min)

# 3. Accès
make cloud-status  # Affiche les URLs
```

## 📚 Documentation additionnelle

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [TypeORM Guide](https://typeorm.io/)
- [Grafana Loki](https://grafana.com/docs/loki/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---
