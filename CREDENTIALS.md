# 🔐 Credentials - CIA Application

## 📱 Application Frontend (http://localhost:8080)

### Utilisateur par défaut
- **Email (username):** `admin` *(entrez "admin" dans le champ email)*
- **Password:** `admin`
- **Role:** ADMIN

> 📝 **Note:** Le frontend affiche "Email" mais attend en réalité le username. Entrez simplement `admin` dans le champ email.

> ⚠️ **Important:** Changez ce mot de passe en production !

---

## 🗄️ Base de données MariaDB

- **Host:** localhost:3306
- **Database:** `cia_database`
- **Username:** `root`
- **Password:** `SecurePassword123!`

### Connexion via terminal
```bash
# Depuis l'hôte
make shell-db

# Ou directement
docker exec -it cia-app-db-1 mariadb -uroot -pSecurePassword123! cia_database
```

---

## 📊 Grafana (http://localhost:3000)

- **Username:** `admin`
- **Password:** `GrafanaAdmin2025!`

### Dashboard des logs
- Nom: CIA Application Logs Dashboard
- Auto-provisionné au démarrage

---

## 🐳 Portainer (http://localhost:9000)

- **Username:** À définir lors de la première connexion
- **Password:** `PortainerAdmin2025!`

---

## 🔧 Comment changer les mots de passe

### 1. Frontend Admin
Pour changer le mot de passe admin du frontend, connectez-vous puis allez dans les paramètres utilisateur.

### 2. Base de données
Modifiez les variables dans `.env`:
```env
DB_PASSWORD=NouveauMotDePasse
DB_ROOT_PASSWORD=NouveauMotDePasse
```
Puis redémarrez:
```bash
make restart
```

### 3. Grafana
Modifiez dans `.env`:
```env
GRAFANA_ADMIN_PASSWORD=NouveauMotDePasse
```
Puis redémarrez:
```bash
docker compose -f ops/docker-compose.yml restart grafana
```

---

## 🚀 Commandes utiles

```bash
# Voir tous les utilisateurs de l'application
docker exec cia-app-db-1 mariadb -uroot -pSecurePassword123! -e "USE cia_database; SELECT id, username, role FROM user;"

# Créer un nouvel utilisateur (via l'API)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"newuser","password":"password123","role":"USER"}'

# Tester la connexion
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

---

## 📝 Notes de sécurité

1. **Tous ces mots de passe doivent être changés en production**
2. Utilisez des mots de passe forts et uniques
3. Ne commitez jamais les fichiers `.env` avec des vrais mots de passe
4. Activez l'authentification à deux facteurs si disponible
5. Limitez l'accès aux ports en production (utilisez un reverse proxy)