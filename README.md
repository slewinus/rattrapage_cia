# CIA Application - Infrastructure Cloud & DevOps

## Sommaire
- [Présentation](#présentation)  
- [Architecture](#architecture)  
- [Déploiement local](#déploiement-local)  
- [Déploiement Azure](#déploiement-azure)  
- [Ansible](#ansible)  
- [Terraform](#terraform)  
- [Services et accès](#services-et-accès)  
- [API](#api)  
- [Monitoring](#monitoring)  
- [Commandes utiles](#commandes-utiles)  
- [Dépannage](#dépannage)  
- [Identifiants et sécurité](#identifiants-et-sécurité)  

---

## Présentation

Application déployable en local ou dans Azure.  
Stack technique :  
- **Frontend** : React + TypeScript  
- **Backend** : Node.js (Express, TypeORM, JWT)  
- **Base de données** : MariaDB  
- **Proxy** : Traefik (HTTPS auto)  
- **Outils** : Gitea, Portainer  
- **Monitoring** : Grafana, Prometheus, Loki  
- **Infra** : Terraform + Ansible, Docker Compose  

---

## Architecture

```
rattrapage_cia/
├── app/           # Backend (Node) + Frontend (React)
├── ops/           # Traefik, Grafana, Prometheus, Loki
├── terraform/     # Provision Azure
├── ansible/       # Déploiement serveur
├── Makefile       # Commandes simplifiées
└── .env           # Variables globales
```

---

## Déploiement local

### Prérequis
- Docker + Docker Compose v2  
- Make  
- 8 Go RAM, ports 80 et 443 libres  

### Installation
```bash
git clone <repo>
cd rattrapage_cia
make quick-start
```

### Accès
- App : https://app.localhost  
- API : https://api.localhost  
- Grafana : https://grafana.localhost  
- Portainer : https://portainer.localhost  
- Gitea : https://gitea.localhost  
- Traefik : https://traefik.localhost  

---

## Déploiement Azure

- RG : `cia-prod-rg`  
- VM : Standard_B2s (Ubuntu 22.04)  
- Disque : 30 Go SSD Premium  
- Réseau : VNet + NSG (22, 80, 443, 2223)  
- DNS : sslip.io  

### Déploiement complet
```bash
make cloud-up      # Provision Azure
make cloud-deploy  # Déploie l’app
```

Terraform fournit l’IP publique et les URLs (app, api, grafana, portainer, gitea, traefik).  

---

## Ansible

Playbook principal (`ansible/site.yml`) :  
- Installe les paquets de base  
- Installe Docker + Compose  
- Déploie l’application et configure Traefik/SSL  

Commandes :  
```bash
ansible-playbook -i "X.X.X.X," -u azureuser ansible/site.yml
```

---

## Terraform

Principales ressources :  
- Resource Group  
- Réseau + Subnet + NSG  
- VM Linux Ubuntu  
- IP publique statique  

Variables principales :  
- `subscription_id`  
- `location` (par défaut `westeurope`)  
- `vm_size` (par défaut `Standard_B2s`)  
- `admin_username`  

---

## Services et accès

| Service      | URL                            | Identifiants par défaut |
|--------------|--------------------------------|--------------------------|
| App          | https://app.X-X-X-X.sslip.io   | admin / admin |
| API          | https://api.X-X-X-X.sslip.io   | JWT Token |
| Grafana      | https://grafana.X-X-X-X.sslip.io | admin / GrafanaAdmin2025! |
| Portainer    | https://portainer.X-X-X-X.sslip.io | admin / PortainerAdmin2025! |
| Gitea        | https://gitea.X-X-X-X.sslip.io | gitea_admin / GiteaAdmin2025! |
| Traefik      | https://traefik.X-X-X-X.sslip.io | admin / TraefikAdmin2025! |

---

## API

- Framework : Express.js  
- ORM : TypeORM  
- Authentification : JWT  
- Base : MariaDB  

Endpoints principaux :  
```
POST   /auth/login
POST   /auth/register
GET    /auth/profile
GET    /users
POST   /users
PUT    /users/:id
DELETE /users/:id
```

---

## Monitoring

- Logs : Loki + Promtail  
- Métriques : Prometheus  
- Dashboards : Grafana  

Exemple de requête Loki :  
```logql
{container_name="cia-app-api-1"} |= "error"
```

---

## Commandes utiles

### Make
```bash
make start        # Démarre les services
make stop         # Stoppe les services
make logs-api     # Logs API
make db-reset     # Réinitialise la BDD
make cloud-up     # Terraform apply
make cloud-deploy # Ansible deploy
```

### Docker
```bash
docker ps -a
docker logs -f <container>
docker system prune -a
```

---

## Dépannage

- **Ports occupés**  
```bash
sudo lsof -i :80
sudo kill -9 <PID>
```

- **Containers KO**  
```bash
docker logs <service>
docker compose up --force-recreate
```

- **Certificats SSL**  
```bash
docker volume rm cia-ops_letsencrypt
make restart
```

---

## Identifiants et sécurité

### Utilisateurs par défaut
| Username  | Password   | Role   |
|-----------|------------|--------|
| admin     | admin      | ADMIN  |
| manager   | manager123 | USER   |
| developer | dev123     | USER   |
| test      | test123    | USER   |
| guest     | guest123   | USER   |

### Points à sécuriser en production
- Changer tous les mots de passe  
- Modifier `JWT_SECRET` dans `.env`  
- Restreindre SSH par firewall  
- Mettre en place des backups  
- Utiliser Key Vault pour les secrets  

---

## Quick Start Production
```bash
git clone <repo>
cd rattrapage_cia
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
make cloud-up
make cloud-deploy
```
