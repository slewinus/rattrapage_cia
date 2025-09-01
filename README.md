# 🚀 CIA Application - Guide Complet

## 📋 Table des matières
- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Installation rapide](#installation-rapide)
- [Accès aux services](#accès-aux-services)
- [Configuration](#configuration)
- [Commandes utiles](#commandes-utiles)
- [Dépannage](#dépannage)

## 🎯 Vue d'ensemble

Application complète avec stack moderne incluant :
- **Frontend** : React avec TypeScript
- **Backend** : Node.js avec Express et TypeORM
- **Base de données** : MariaDB
- **Monitoring** : Grafana + Loki + Promtail
- **Gestion Docker** : Portainer

## 🏗️ Architecture

```
cia-app/
├── app/                    # Application principale
│   ├── back_student/       # API Backend (Node.js)
│   ├── front_student/      # Frontend React
│   └── docker-compose.yml  # Services applicatifs
├── ops/                    # Services de monitoring
│   ├── grafana/           # Configuration Grafana
│   ├── loki-config.yml    # Configuration Loki
│   └── docker-compose.yml # Services monitoring
├── .env                   # Configuration globale
└── Makefile              # Commandes simplifiées
```

## 🔒 Reverse Proxy (HTTPS via Traefik)

Traefik termine le TLS et route vers les services cibles. Des hôtes locaux sont exposés en HTTPS (certificat auto-signé par défaut) :

- Frontend: https://app.localhost
- API: https://api.localhost
- Grafana: https://grafana.localhost
- Portainer: https://portainer.localhost
- Gitea: https://gitea.localhost (SSH: `ssh://git@localhost:2222`)

Notes:
- Redirection HTTP→HTTPS automatique.
- Pour un certificat de confiance, fournissez vos propres certs via `ops/traefik/dynamic` ou utilisez `mkcert`.

## ⚡ Installation rapide

### 1. Cloner le projet
```bash
git clone <repository-url>
cd rattrapage_CIA
```

### 2. Configuration
Les fichiers `.env` sont déjà configurés avec des valeurs par défaut sécurisées.
Pour personnaliser, modifiez les fichiers :
- `.env` : Configuration globale
- `app/.env` : Configuration application
- `ops/.env` : Configuration monitoring

### 3. Lancer le projet
```bash
# Installation et lancement en une commande
make quick-start

# OU séparément :
make build   # Build des images
make start   # Lancement des services
```

## 🔐 Accès aux services

### 📱 Application principale

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend React** | https://app.localhost | Email: `admin`<br>Pass: `admin` |
| **API Backend** | https://api.localhost | Via token JWT après login |
| **Base de données** | `localhost:3306` | User: `root`<br>Pass: `SecurePassword123!`<br>DB: `cia_database` |

### 📊 Monitoring & Administration

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | https://grafana.localhost | User: `admin`<br>Pass: `GrafanaAdmin2025!` |
| **Loki (Logs)** | Interne (via Grafana) | — |
| **Portainer** | https://portainer.localhost | Pass: `PortainerAdmin2025!` |
| **Gitea** | https://gitea.localhost | User: `gitea_admin`<br>Pass: `GiteaAdmin2025!` |
| **Gitea SSH** | `ssh://git@localhost:2223` | Configure SSH keys in Gitea |

## ⚙️ Configuration

### Variables d'environnement principales

#### 🗄️ Base de données
```env
DB_USER=root
DB_PASSWORD=SecurePassword123!
DB_NAME=cia_database
```

#### 🔌 API Backend
```env
NODE_ENV=production
API_PORT=3000
JWT_SECRET=your-super-secret-jwt-key-change-me-in-production
```

#### 🎨 Frontend
```env
REACT_APP_API_URL=/api
REACT_APP_ENVIRONMENT=production
```

#### 📊 Monitoring
```env
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=GrafanaAdmin2025!
PORTAINER_ADMIN_PASSWORD=PortainerAdmin2025!
```

#### 🔧 Gitea (Git Server)
```env
GITEA_WEB_PORT=3001
GITEA_SSH_PORT=2223
GITEA_ADMIN_USER=gitea_admin
GITEA_ADMIN_PASSWORD=GiteaAdmin2025!
GITEA_ADMIN_EMAIL=admin@gitea.local
```

### Modification des mots de passe

1. Éditez le fichier `.env` correspondant
2. Redémarrez les services :
```bash
make restart
```

## 🛠️ Commandes utiles

### Commandes principales
```bash
make start       # Lance tous les services
make stop        # Arrête tous les services
make restart     # Redémarre tous les services
make status      # Affiche l'état des services
make logs        # Affiche les logs en temps réel
make test        # Lance les tests de santé
```

### Build et maintenance
```bash
make build       # Rebuild les images Docker
make clean       # Nettoie tout (containers + volumes)
make db-reset    # Réinitialise la base de données
```

### Accès aux shells
```bash
make shell-api   # Shell dans le container API
make shell-db    # Console MySQL
make shell-gitea # Shell dans le container Gitea
```

### Gitea
```bash
make gitea-admin # Créer le compte admin Gitea (après le premier démarrage)
```

## 📈 Monitoring avec Grafana

### Configuration initiale
1. Accédez à https://grafana.localhost (acceptez l’avertissement de certificat si nécessaire)
2. Connectez-vous avec `admin` / `GrafanaAdmin2025!`
3. Loki est déjà configuré comme source de données

### Visualiser les logs
1. Allez dans **Explore** (icône compass)
2. Sélectionnez **Loki** comme source
3. Utilisez ces requêtes :
   - Tous les logs : `{job="docker"}`
   - Logs API : `{container_name="cia-app-api-1"}`
   - Logs Frontend : `{container_name="cia-app-web-1"}`

## 🐳 Gestion avec Portainer

1. Accédez à https://portainer.localhost (acceptez l’avertissement de certificat si nécessaire)
2. Première connexion : définissez un nom d'utilisateur admin
3. Mot de passe : `PortainerAdmin2025!`
4. Sélectionnez **Local** pour gérer Docker local

### Fonctionnalités utiles
- Visualisation des containers
- Logs en temps réel
- Redémarrage de services
- Inspection des volumes
- Monitoring des ressources

## 🔧 Dépannage

### L'application ne démarre pas
```bash
# Vérifier l'état des services
make status

# Voir les logs
make logs

# Redémarrer
make restart
```

### Problèmes de base de données
```bash
# Réinitialiser la base de données
make db-reset

# Accéder à MySQL
make shell-db
```

### Ports déjà utilisés
Les services ne publient plus de ports HTTP individuels (tout passe via Traefik en 80/443). Si des ports 80/443 sont pris, arrêtez les services en conflit ou ajustez la config Traefik.

### Nettoyer complètement
```bash
# Arrête et supprime tout
make clean

# Supprime aussi les volumes (ATTENTION: perte de données)
docker volume prune -f
```

## 📝 Notes importantes

1. **Sécurité** : Changez tous les mots de passe en production
2. **Performances** : Les images utilisent Alpine Linux pour réduire la taille
3. **Cache** : Docker BuildKit est activé pour des builds plus rapides
4. **Logs** : Tous les logs sont centralisés dans Loki via Promtail

## 🤝 Support

Pour toute question ou problème :
1. Vérifiez les logs : `make logs`
2. Consultez l'état : `make status`
3. Redémarrez si nécessaire : `make restart`

---

📌 **Quick Start**: `make quick-start` pour tout lancer en une commande !
