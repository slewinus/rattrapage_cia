# CIA Infrastructure Automation

Infrastructure as Code pour déployer automatiquement l'application CIA sur Azure avec toutes les applications Docker.

## 🚀 Démarrage Rapide

```bash
# Installation complète en une commande
make quick-start
```

Cette commande va :
1. Installer les dépendances (Terraform, Ansible, Azure CLI)
2. Initialiser Terraform
3. Créer la VM Azure
4. Déployer automatiquement toutes les applications

## 📋 Prérequis

- Un compte Azure avec un abonnement actif
- SSH key pair (`~/.ssh/id_rsa` et `~/.ssh/id_rsa.pub`)
- macOS/Linux (pour Windows, utilisez WSL)

## 🏗️ Architecture

### Infrastructure Azure
- **VM**: Standard_B2s (2 vCPU, 4 GB RAM)
- **Réseau**: VNet avec subnet dédié
- **Sécurité**: NSG avec règles pour HTTP/HTTPS/SSH
- **IP Publique**: Statique pour accès stable

### Applications Déployées
- **Frontend**: Application React
- **Backend**: API Node.js/Python
- **Traefik**: Reverse proxy avec SSL automatique
- **Grafana**: Monitoring et dashboards
- **Portainer**: Gestion des containers
- **Gitea**: Git server self-hosted
- **PostgreSQL**: Base de données

## 🔧 Configuration

### Variables Terraform

Editez `terraform/azure-vm/terraform.tfvars`:

```hcl
project         = "cia"
environment     = "prod"
location        = "francecentral"
vm_size         = "Standard_B2s"
admin_username  = "azureuser"

# URL de votre repo Git
git_repo_url    = "https://github.com/slewinus/rattrapage_cia"
git_repo_branch = "main"

# Email pour Let's Encrypt (Traefik)
acme_email      = "admin@example.com"

# IPs autorisées pour SSH (optionnel)
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Déploiement automatique des apps après création de la VM (défaut: true)
auto_deploy_apps = true
```

## 📝 Commandes Disponibles

```bash
# Commandes Terraform
make init          # Initialiser Terraform
make plan          # Voir les changements prévus
make apply         # Créer/Mettre à jour l'infrastructure
make destroy       # Détruire toute l'infrastructure

# Déploiement des applications
make deploy        # Déployer les apps avec Ansible
make redeploy      # Redéployer les apps (mise à jour)

# Monitoring et debug
make ssh           # Se connecter en SSH à la VM
make check-services # Vérifier le statut des services
make urls          # Afficher les URLs des services
make logs          # Voir les logs Docker

# Maintenance
make clean         # Nettoyer les fichiers locaux
make install-deps  # Installer les dépendances
```

## 🌐 Accès aux Services

Après le déploiement, vos services sont accessibles via :

- **Application**: https://app.{IP}.sslip.io
- **API**: https://api.{IP}.sslip.io
- **Grafana**: https://grafana.{IP}.sslip.io
- **Portainer**: https://portainer.{IP}.sslip.io
- **Gitea**: https://gitea.{IP}.sslip.io
- **Traefik**: https://traefik.{IP}.sslip.io

Les certificats SSL sont générés automatiquement via Let's Encrypt.

## 🔄 Modes de Déploiement

### Déploiement Ansible (par défaut)

Par défaut, Terraform provisionne la VM, puis lance Ansible pour installer Docker, cloner le dépôt et démarrer les stacks Docker.

Pour relancer le déploiement applicatif sans toucher à l'infra :

```bash
make deploy
```

### Mode 3: Déploiement Manuel

Connectez-vous en SSH et déployez manuellement :

```bash
make ssh
cd /opt/cia
docker compose -f ops/docker-compose.yml up -d
docker compose -f app/docker-compose.yml up -d
```

## 🔒 Sécurité

- Les mots de passe sont générés automatiquement
- HTTPS obligatoire avec certificats Let's Encrypt
- NSG Azure pour limiter les accès
- SSH uniquement depuis les IPs autorisées

## 🐛 Dépannage

### Les services ne démarrent pas

```bash
# Vérifier le statut
make check-services

# Voir les logs
make ssh
sudo journalctl -u deploy-apps -f
docker ps -a
docker logs <container_name>
```

### Erreur Terraform

```bash
# Rafraîchir l'état
cd terraform/azure-vm
terraform refresh

# Importer les ressources existantes
terraform import azurerm_network_security_group.nsg /subscriptions/.../cia-prod-nsg
```

### Redéployer après modification

```bash
# Si vous avez modifié le code
git push origin main

# Sur votre machine locale
make redeploy
```

## 📊 Monitoring

Grafana est pré-configuré avec des dashboards pour :
- Métriques système (CPU, RAM, Disque)
- Métriques Docker
- Logs applicatifs
- Métriques Traefik

## 🔄 Mise à jour

Pour mettre à jour les applications :

```bash
# Méthode 1: Via Ansible
make redeploy

# Méthode 2: Sur la VM
make ssh
cd /opt/cia
git pull
docker compose up -d --build
```

## 💾 Backup

Les données importantes sont dans `/opt/cia/data`.

Backup recommandé :
```bash
# Sur la VM
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/cia/data
```

## 📚 Structure du Projet

```
infra/
├── terraform/
│   └── azure-vm/
│       ├── main.tf              # Configuration Terraform
│       ├── variables.tf         # Variables
│       ├── terraform.tfvars     # Valeurs des variables
│       ├── cloud-init.yaml      # Script basique
│       └── cloud-init-enhanced.yaml  # Script avec auto-deploy
├── ansible/
│   ├── inventory.yml            # Inventaire Ansible
│   ├── site.yml                 # Playbook principal
│   └── playbook-full-deploy.yml # Wrapper utilisé par Terraform
├── Makefile                    # Commandes automatisées
└── README.md                   # Documentation
```

## ⚠️ Important

- **Coûts Azure**: La VM Standard_B2s coûte environ 30€/mois
- **Sécurité**: Changez les mots de passe par défaut après le déploiement
- **Backup**: Configurez des snapshots Azure pour la VM

## 🆘 Support

En cas de problème :
1. Vérifiez les logs : `make logs`
2. Consultez le status : `make check-services`
3. Redémarrez les services : `make redeploy`

---

Développé avec ❤️ pour le projet CIA
