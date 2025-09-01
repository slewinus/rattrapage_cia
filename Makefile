# ====== Config ======
APP_COMPOSE := app/docker-compose.yml
OPS_COMPOSE := ops/docker-compose.yml
ENV_FILE    := .env

FRONT_URL   := http://localhost:${WEB_PORT:-8080}
API_BASE    := http://localhost:${WEB_PORT:-8080}/api
LOKI_READY  := http://localhost:${LOKI_PORT:-3100}/ready

CURL := curl -sS -o /dev/null -w "%{http_code}"

# Couleurs pour les messages
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ====== Raccourcis principaux ======
.PHONY: help start stop restart build logs clean status quick-start

help:
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)            🚀 CIA App - Commandes disponibles$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)🔥 Commandes rapides:$(NC)"
	@echo "  $(GREEN)make start$(NC)       -> Lance tout le projet (monitoring + app)"
	@echo "  $(GREEN)make stop$(NC)        -> Arrête tout le projet"
	@echo "  $(GREEN)make restart$(NC)     -> Redémarre le projet"
	@echo "  $(GREEN)make logs$(NC)        -> Affiche les logs de l'application"
	@echo "  $(GREEN)make status$(NC)      -> Affiche l'état des services"
	@echo ""
	@echo "$(YELLOW)📦 Build et maintenance:$(NC)"
	@echo "  $(GREEN)make build$(NC)       -> Rebuild les images Docker"
	@echo "  $(GREEN)make clean$(NC)       -> Nettoie tout (containers + images)"
	@echo "  $(GREEN)make test$(NC)        -> Lance les tests"
	@echo ""
	@echo "$(YELLOW)🎯 Démarrage ultra-rapide:$(NC)"
	@echo "  $(GREEN)make quick-start$(NC) -> Build et lance tout en une commande"
	@echo ""
	@echo "$(YELLOW)📍 URLs d'accès:$(NC)"
	@echo "  Frontend:  $(GREEN)https://app.localhost$(NC)"
	@echo "  Grafana:   $(GREEN)https://grafana.localhost$(NC) (admin/GrafanaAdmin2025!)"
	@echo "  Gitea:     $(GREEN)https://gitea.localhost$(NC)"
	@echo "  Portainer: $(GREEN)https://portainer.localhost$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"

# ====== Commandes principales ======
start: ops-up app-up
	@echo ""
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✅ Application démarrée avec succès!$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "  Frontend:  $(GREEN)https://app.localhost$(NC)"
	@echo "  Grafana:   $(GREEN)https://grafana.localhost$(NC)"
	@echo "  Gitea:     $(GREEN)https://gitea.localhost$(NC)"
	@echo "  Portainer: $(GREEN)https://portainer.localhost$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"

stop: app-down ops-down
	@echo "$(YELLOW)⏹  Projet arrêté$(NC)"

restart: stop start

logs: app-logs

status:
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)📊 État des services$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

quick-start: build start
	@echo "$(GREEN)🎉 Projet prêt en un temps record!$(NC)"

build:
	@echo "$(YELLOW)🔨 Build des images Docker avec cache optimisé...$(NC)"
	@export DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 && \
	docker compose -f $(APP_COMPOSE) build --parallel
	@echo "$(GREEN)✅ Build terminé$(NC)"

# ====== OPS (Monitoring) ======
ops-up:
	@echo "$(YELLOW)🚀 Démarrage du monitoring (Traefik/Loki/Grafana/Portainer)...$(NC)"
	@docker network inspect traefik >/dev/null 2>&1 || docker network create traefik
	@docker compose -p cia-ops -f $(OPS_COMPOSE) --env-file $(ENV_FILE) up -d
	@echo "$(YELLOW)⏳ Attente que Loki soit prêt...$(NC)"
	@i=0; until [ $$i -ge 30 ] || docker compose -f $(OPS_COMPOSE) exec -T loki wget -q --spider http://localhost:3100/ready 2>/dev/null; do \
		i=$$((i+1)); \
		printf "."; \
		sleep 1; \
	done; echo ""
	@echo "$(GREEN)✅ Monitoring prêt$(NC)"

ops-down:
	@echo "$(YELLOW)⏹  Arrêt du monitoring...$(NC)"
	@docker compose -p cia-ops -f $(OPS_COMPOSE) down

ops-logs:
	docker compose -f $(OPS_COMPOSE) logs -f

# ====== APP ======
app-up:
	@echo "$(YELLOW)🚀 Démarrage de l'application...$(NC)"
	@docker network inspect traefik >/dev/null 2>&1 || docker network create traefik
	@docker compose -f $(APP_COMPOSE) --env-file $(ENV_FILE) up -d
	@echo "$(GREEN)✅ Application démarrée$(NC)"

app-down:
	@echo "$(YELLOW)⏹  Arrêt de l'application...$(NC)"
	@docker compose -f $(APP_COMPOSE) down

app-logs:
	docker compose -f $(APP_COMPOSE) logs -f

app-restart: app-down app-up

# ====== Tests ======
test:
	@echo "$(YELLOW)🧪 Lancement des tests...$(NC)"
	@sleep 5
	@echo "$(YELLOW)Test Frontend...$(NC)"
	@curl -f -s http://localhost:8080 > /dev/null && echo "$(GREEN)✅ Frontend OK$(NC)" || echo "$(RED)❌ Frontend KO$(NC)"
	@echo "$(YELLOW)Test API...$(NC)"
	@curl -f -s http://localhost:8080/api/health > /dev/null 2>&1 && echo "$(GREEN)✅ API OK$(NC)" || echo "$(YELLOW)⚠️  API en cours de démarrage$(NC)"
	@echo "$(YELLOW)Test Monitoring...$(NC)"
	@curl -f -s http://localhost:3100/ready > /dev/null 2>&1 && echo "$(GREEN)✅ Loki OK$(NC)" || echo "$(YELLOW)⚠️  Loki non démarré$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"

# ====== Nettoyage ======
clean:
	@echo "$(YELLOW)🧹 Nettoyage complet...$(NC)"
	@docker compose -f $(APP_COMPOSE) down -v
	@docker compose -f $(OPS_COMPOSE) down -v
	@docker system prune -f
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

# ====== Utilitaires ======
shell-api:
	@docker compose -f $(APP_COMPOSE) exec api sh

shell-db:
	@docker compose -f $(APP_COMPOSE) exec db mariadb -uroot -p$$DB_PASSWORD $$DB_NAME

shell-gitea: ## Accéder au shell Gitea
	@echo "$(GREEN)Connexion au container Gitea...$(NC)"
	@docker exec -it cia-ops-gitea-1 /bin/sh

gitea-admin: ## Créer un compte admin Gitea
	@echo "$(GREEN)Création du compte admin Gitea...$(NC)"
	@docker exec cia-ops-gitea-1 gitea admin user create \
		--username $${GITEA_ADMIN_USER:-gitea_admin} \
		--password $${GITEA_ADMIN_PASSWORD:-GiteaAdmin2025!} \
		--email $${GITEA_ADMIN_EMAIL:-admin@gitea.local} \
		--admin || echo "Admin might already exist"

db-reset:
	@docker compose -f $(APP_COMPOSE) down -v
	@docker volume rm cia-app_db-data 2>/dev/null || true
	@echo "$(GREEN)✅ Base de données réinitialisée$(NC)"

# ====== Alias pour compatibilité ======
.PHONY: dev-up dev-down ps
dev-up: start
dev-down: stop
ps: status
tls-mkcert:
	@echo "$(YELLOW)🔐 Generating local TLS certs with mkcert...$(NC)"
	@mkdir -p ops/traefik/dynamic/certs
	@if command -v mkcert >/dev/null 2>&1; then \
		mkcert -install >/dev/null 2>&1 || true; \
		mkcert -cert-file ops/traefik/dynamic/certs/local-cert.pem -key-file ops/traefik/dynamic/certs/local-key.pem app.localhost api.localhost grafana.localhost portainer.localhost gitea.localhost traefik.localhost localhost 127.0.0.1 ::1; \
		printf '%s\n' "tls:" "  certificates:" "    - certFile: /etc/traefik/dynamic/certs/local-cert.pem" "      keyFile: /etc/traefik/dynamic/certs/local-key.pem" > ops/traefik/dynamic/tls.yml; \
		echo "$(GREEN)✅ Certs generated. Restarting Traefik...$(NC)"; \
		docker compose -p cia-ops -f $(OPS_COMPOSE) up -d traefik; \
	else \
		echo "$(RED)mkcert not found. Install: https://github.com/FiloSottile/mkcert$(NC)"; \
	fi
