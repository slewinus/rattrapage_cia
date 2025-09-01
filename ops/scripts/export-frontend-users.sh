#!/usr/bin/env bash
set -euo pipefail

# Exporte la liste des utilisateurs frontend (id, username, role) sans mot de passe
# Usage: ops/scripts/export-frontend-users.sh [chemin_de_sortie]

OUTPUT_PATH=${1:-reports/frontend_users.csv}
DB_CONTAINER_NAME=${DB_CONTAINER_NAME:-cia-app-db-1}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-SecurePassword123!}
DB_NAME=${DB_NAME:-cia_database}

mkdir -p "$(dirname "$OUTPUT_PATH")"

echo "> Export des utilisateurs depuis '$DB_CONTAINER_NAME' (DB: $DB_NAME)"

# Ajoute un header et exporte les colonnes utiles. Pas de hash ni de mot de passe.
docker exec -i "$DB_CONTAINER_NAME" \
  mariadb -uroot -p"$DB_ROOT_PASSWORD" -N -e \
  "USE $DB_NAME; SELECT 'id','username','role' UNION ALL SELECT id, username, role FROM user;" \
  > "$OUTPUT_PATH"

echo "OK: Export sauvegardé dans $OUTPUT_PATH"

