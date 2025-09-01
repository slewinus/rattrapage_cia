#  Guide d'intégration Vault - Next Steps

##  Ce qui est déjà fait

1. **Vault est opérationnel** sur `http://localhost:8201`
2. **Tous vos secrets sont migrés** dans Vault
3. **Module Node.js créé** pour l'intégration (`vault-client.js`)
4. **Fail2ban configuré** (à activer selon l'OS)

## Next Steps - Intégration complète

### 1. **Mettre à jour votre API pour utiliser Vault**

#### Modifier le fichier principal de l'API
```javascript
// app/back_student/src/index.js ou app.js
const vaultClient = require('./src/vault-client');
const { initializeDatabase } = require('./src/config/database-vault');

// Au démarrage de l'application
async function startServer() {
  try {
    // Initialiser la connexion DB avec Vault
    await initializeDatabase();
    
    // Récupérer la config depuis Vault
    const apiConfig = await vaultClient.getApiConfig();
    const jwtSecret = await vaultClient.getJwtSecret();
    
    // Utiliser les secrets
    app.listen(apiConfig.api_port, () => {
      console.log(`Server running on port ${apiConfig.api_port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}
```

### 2. **Mettre à jour le docker-compose pour passer le token Vault**

```yaml
# app/docker-compose.yml
services:
  api:
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: ${VAULT_TOKEN_API:-myroot}  # Utiliser un token dédié en prod
```

### 3. **Créer des tokens dédiés par service**

```bash
# Créer un token pour l'API (avec politique restrictive)
curl -X POST \
  -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/auth/token/create \
  -d '{
    "policies": ["api-policy"],
    "ttl": "720h",
    "renewable": true
  }'
```

### 4. **Automatiser le renouvellement des tokens**

```javascript
// Ajouter dans vault-client.js
async renewToken() {
  try {
    const response = await fetch(`${this.vaultAddr}/v1/auth/token/renew-self`, {
      method: 'POST',
      headers: { 'X-Vault-Token': this.vaultToken }
    });
    console.log('[Vault] Token renewed successfully');
  } catch (error) {
    console.error('[Vault] Failed to renew token:', error);
  }
}

// Renouveler automatiquement toutes les 12h
setInterval(() => this.renewToken(), 12 * 60 * 60 * 1000);
```

### 5. **Implémenter la rotation des secrets**

```bash
# Script de rotation (à exécuter régulièrement)
#!/bin/bash
# rotate-secrets.sh

# Générer un nouveau JWT secret
NEW_JWT=$(openssl rand -base64 32)

# Mettre à jour dans Vault
curl -X POST \
  -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/secret/data/api/config \
  -d "{\"data\": {\"jwt_secret\": \"$NEW_JWT\"}}"

# Redémarrer les services pour appliquer
docker compose -f app/docker-compose.yml restart api
```

##  Bonnes pratiques en production

### 1. **Ne JAMAIS utiliser le root token en production**
```bash
# Créer des tokens avec des politiques limitées
vault token create -policy=api-policy -ttl=24h
```

### 2. **Activer l'audit log de Vault**
```bash
vault audit enable file file_path=/vault/logs/audit.log
```

### 3. **Utiliser le chiffrement TLS**
```yaml
# Dans vault-config.json
"listener": {
  "tcp": {
    "address": "0.0.0.0:8200",
    "tls_cert_file": "/vault/certs/cert.pem",
    "tls_key_file": "/vault/certs/key.pem"
  }
}
```

### 4. **Implémenter le unsealing automatique**
```bash
# Utiliser AWS KMS, Azure Key Vault ou Google Cloud KMS
# pour auto-unseal Vault au démarrage
```

## Commandes utiles

```bash
# Voir tous les secrets
curl -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/secret/metadata?list=true | jq

# Lire un secret spécifique
curl -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/secret/data/database/mysql | jq

# Mettre à jour un secret
curl -X POST -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/secret/data/api/new-secret \
  -d '{"data": {"key": "value"}}'

# Supprimer un secret
curl -X DELETE -H "X-Vault-Token: myroot" \
  http://localhost:8201/v1/secret/data/api/old-secret
```

##  Monitoring de Vault

### Ajouter à Prometheus
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'vault'
    metrics_path: '/v1/sys/metrics'
    params:
      format: ['prometheus']
    bearer_token: 'myroot'
    static_configs:
      - targets: ['vault:8200']
```

### Dashboard Grafana
- Importer le dashboard ID: 12904 (HashiCorp Vault)
- Métriques importantes:
  - vault_core_unsealed
  - vault_token_count
  - vault_secret_kv_count
  - vault_audit_log_request_count

##  Prochaines améliorations

1. **High Availability** : Configurer Vault en mode HA avec Raft
2. **Dynamic Secrets** : Générer des credentials DB temporaires
3. **PKI** : Utiliser Vault comme CA interne
4. **SSH** : Gérer les clés SSH via Vault
5. **Encryption as a Service** : Chiffrer les données sensibles

##  Checklist de sécurité

- [ ] Root token sécurisé et non utilisé en prod
- [ ] Policies restrictives pour chaque service
- [ ] Audit logs activés
- [ ] TLS configuré
- [ ] Backup régulier de Vault
- [ ] Rotation des secrets planifiée
- [ ] Monitoring des accès anormaux
- [ ] Plan de disaster recovery

## 📚 Ressources

- [Vault Best Practices](https://learn.hashicorp.com/tutorials/vault/production-hardening)
- [Vault API Docs](https://www.vaultproject.io/api-docs)
- [Node.js Vault Client](https://github.com/kr1sp1n/node-vault)