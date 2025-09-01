# Inventaire comptes et secrets (Local / Prod)

Ce document centralise les points d’accès et emplacements des secrets sans exposer de mots de passe en clair. Utilisez les variables d’environnement en local et Vault en production.

## Frontend – Utilisateurs de l’application

- Logins: stockés dans MariaDB (`user.username`), rôles dans `user.role`.
- Export des logins (sans mots de passe):
  - Script: `ops/scripts/export-frontend-users.sh`
  - Exemple: `bash ops/scripts/export-frontend-users.sh reports/frontend_users.csv`
- Admins applicatifs: utilisateurs avec `role = 'ADMIN'`.
  - SQL: `SELECT id, username FROM user WHERE role='ADMIN';`
- Mots de passe: jamais accessibles en clair (hashés en base). Pour réinitialiser, passer par l’API d’admin ou une procédure dédiée (reset token), pas par extraction.

## Comptes d’administration des services

Remarque: les valeurs concrètes sont définies par variables en local et dans Vault en prod. Ne stockez pas de mots de passe en clair ici.

### Traefik (dashboard)
- Login local: défini via `TRAEFIK_DASHBOARD_AUTH` (basic auth htpasswd bcrypt) dans `ops/docker-compose.yml`.
- Login prod: gérer via Vault ou fichier `.htpasswd` provisionné (ne pas committer), variable attendue: `TRAEFIK_DASHBOARD_AUTH`.

### Grafana
- Login local: `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` (voir `ops/.env.example` et `ops/docker-compose.yml`).
- Login prod (Vault): `secret/monitoring/grafana` → clés `admin_user`, `admin_password`.

### Portainer
- Login local: `PORTAINER_ADMIN_PASSWORD` (init lors de la première connexion, variable dans `ops/.env.example`).
- Login prod (Vault): `secret/monitoring/portainer` → clé `admin_password`.

### Gitea
- Login local: Makefile cible `gitea-admin` utilise:
  - `GITEA_ADMIN_USER`, `GITEA_ADMIN_PASSWORD`, `GITEA_ADMIN_EMAIL`
- Login prod (Vault): `secret/gitea/config` → `admin_user`, `admin_password`, `admin_email`.

### Base de données MariaDB (app)
- Local: `root` / `DB_ROOT_PASSWORD` et base `DB_NAME` (cf. scripts et compose; ne pas exposer en clair).
- Prod (Vault): `secret/database/mysql` → `username`, `password`, `database`, `root_password`.

## Récapitulatif accès aux secrets

- Local (développement):
  - Fichiers: `.env`, `ops/.env.example` (modèle), variables injectées dans `ops/docker-compose.yml`.
  - Ne pas committer d’identifiants réels dans `.env`.
- Production (Vault):
  - Endroit: `secret/` (KV v2) avec chemins:
    - `secret/monitoring/grafana` (admin Grafana)
    - `secret/monitoring/portainer` (admin Portainer)
    - `secret/gitea/config` (admin Gitea + DB)
    - `secret/database/mysql` (DB app)
  - Initialisation / migration d’exemple: `migrate-secrets-to-vault.sh`

## Bonnes pratiques

- Ne jamais lister ni centraliser des mots de passe en clair.
- Utiliser des comptes nominaux et rôles minimaux (least privilege).
- Renouveler régulièrement les secrets et activer MFA quand disponible.
- Pour audit: exporter les logins/roles (sans secrets) et vérifier les accès actifs.

