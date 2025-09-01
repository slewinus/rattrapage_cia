Scripts utilitaires

- `demo-presentation.sh`: Démo de l'infra (WOW services, trafic de test).
- `migrate-secrets-api.sh`: Migration des secrets vers Vault via API HTTP.
- `migrate-secrets-to-vault.sh`: Migration des secrets via CLI `vault` + création policies/tokens.
- `azure-deploy.sh`: Déploiement VM Azure + provisionning (Terraform, Docker Compose).
- `gen-azure-env.sh`: Génération d'un `.env` à partir d'IP publique (sslip.io).

Bonnes pratiques

- Ne pas commiter de secrets réels. Utiliser `.env.example` comme template.
- Tenir ces scripts dans ce dossier pour éviter la dispersion à la racine.
