#  Guide de Sécurité - CIA App

## Vue d'ensemble

Ce projet intègre **HashiCorp Vault** pour la gestion sécurisée des secrets et **Fail2ban** pour la protection contre les attaques brute-force.

##  HashiCorp Vault

### Démarrage rapide

```bash
# Lancer les services de sécurité
docker compose -f ops/security-compose.yml up -d

# Initialiser Vault (première fois uniquement)
./ops/security-init.sh
```

### Accès à Vault

- **URL**: https://vault.localhost:8443
- **UI**: https://vault-ui.localhost:8443
- **API**: http://localhost:8200 (interne)

### Utilisation dans votre application

#### 1. Récupération des secrets (Node.js)

```javascript
const vault = require('node-vault')({
  endpoint: process.env.VAULT_ADDR || 'http://vault:8200',
  token: process.env.VAULT_TOKEN
});

// Récupérer les credentials de la base de données
async function getDbCredentials() {
  const result = await vault.read('secret/data/database/mysql');
  return result.data.data;
}

// Récupérer le secret JWT
async function getJwtSecret() {
  const result = await vault.read('secret/data/app/jwt');
  return result.data.data.secret;
}
```

#### 2. Structure des secrets

```
secret/
├── database/
│   └── mysql           # Credentials MySQL
├── app/
│   ├── jwt            # Secret JWT
│   └── api-keys       # Clés API externes
└── monitoring/
    └── grafana        # Credentials Grafana
```

### Commandes utiles

```bash
# Se connecter à Vault
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='<your-root-token>'

# Lister les secrets
vault kv list secret/

# Lire un secret
vault kv get secret/database/mysql

# Écrire un nouveau secret
vault kv put secret/app/new-secret key=value

# Créer un token pour l'application
vault token create -policy=app-policy -ttl=720h
```

##  Fail2ban

### Configuration

Fail2ban surveille automatiquement :
- **Traefik** : Tentatives d'accès non autorisées (401/403)
- **API** : Échecs de connexion
- **Grafana** : Tentatives de connexion échouées
- **Gitea** : Accès non autorisés
- **Vault** : Erreurs d'authentification
- **Portainer** : Tentatives de connexion

### Règles par défaut

| Service | Max Tentatives | Fenêtre | Durée de Ban |
|---------|---------------|---------|--------------|
| Traefik | 3 | 5 min | 1 heure |
| API | 10 | 5 min | 10 min |
| Grafana | 3 | 10 min | 1 heure |
| Vault | 3 | 10 min | 2 heures |
| SSH | 3 | 10 min | 1 heure |

### Commandes utiles

```bash
# Voir le statut de Fail2ban
docker compose -f ops/security-compose.yml exec fail2ban fail2ban-client status

# Voir les IPs bannies pour un service
docker compose -f ops/security-compose.yml exec fail2ban fail2ban-client status traefik-auth

# Débannir une IP
docker compose -f ops/security-compose.yml exec fail2ban fail2ban-client unban <IP>

# Voir les logs
docker compose -f ops/security-compose.yml logs fail2ban
```

##  Intégration dans le Makefile

Ajoutez ces commandes à votre Makefile :

```makefile
# Security commands
security-up:
	@echo " Starting security services..."
	@docker compose -f ops/security-compose.yml up -d

security-down:
	@echo "Stopping security services..."
	@docker compose -f ops/security-compose.yml down

security-init:
	@echo " Initializing Vault..."
	@./ops/security-init.sh

vault-ui:
	@echo "Opening Vault UI..."
	@open https://vault-ui.localhost:8443

fail2ban-status:
	@docker compose -f ops/security-compose.yml exec fail2ban fail2ban-client status
```

##  Monitoring de sécurité

### Dashboard Grafana

Un dashboard de sécurité peut être créé pour visualiser :
- Nombre de tentatives bloquées par Fail2ban
- Accès aux secrets Vault
- Tentatives d'authentification échouées
- IPs bannies par service

### Alertes recommandées

1. **Trop de bans** : > 10 IPs bannies en 1 heure
2. **Accès Vault anormal** : > 100 requêtes/minute
3. **Échecs d'authentification** : > 50 échecs en 5 minutes
4. **Service down** : Vault ou Fail2ban non disponible

##  Bonnes pratiques

### Vault

1. **Ne jamais commiter les tokens** dans le code
2. **Rotation régulière** des tokens (tous les 30 jours)
3. **Utiliser des policies** restrictives par application
4. **Activer l'audit log** en production
5. **Chiffrer le backend** de stockage en production

### Fail2ban

1. **Ajuster les seuils** selon votre contexte
2. **Whitelist** les IPs de confiance (CI/CD, monitoring)
3. **Backup régulier** de la base de données Fail2ban
4. **Monitoring** des bans pour détecter les attaques
5. **Logs centralisés** pour analyse forensique

## 🔄 Mise à jour des services

```bash
# Mettre à jour les images
docker compose -f ops/security-compose.yml pull

# Redémarrer avec les nouvelles versions
docker compose -f ops/security-compose.yml up -d

# Vérifier les versions
docker compose -f ops/security-compose.yml exec vault vault version
docker compose -f ops/security-compose.yml exec fail2ban fail2ban-client version
```

## 🆘 Troubleshooting

### Vault sealed

```bash
# Unseal Vault avec 3 clés
vault operator unseal <key-1>
vault operator unseal <key-2>
vault operator unseal <key-3>
```

### IP bannie par erreur

```bash
# Débannir immédiatement
docker compose -f ops/security-compose.yml exec fail2ban \
  fail2ban-client set <jail-name> unbanip <IP>
```

### Perte du root token Vault

1. Générer un nouveau root token (nécessite les unseal keys)
2. Mettre à jour tous les services avec le nouveau token
3. Révoquer l'ancien token si possible

## 📚 Ressources

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Fail2ban Wiki](https://github.com/fail2ban/fail2ban/wiki)
- [Security Best Practices](https://owasp.org/www-project-docker-top-10/)