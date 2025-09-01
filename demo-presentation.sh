#!/bin/bash

# Script de démonstration pour présentation CIA App
# Effet WOW garanti ! 

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      CIA App - Démonstration Infrastructure DevOps${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
sleep 2

echo -e "${CYAN} Agenda de la présentation :${NC}"
echo -e "  1. Architecture microservices"
echo -e "  2. Monitoring temps réel avec Grafana"
echo -e "  3. Gestion des secrets avec HashiCorp Vault"
echo -e "  4. Observabilité avancée"
echo -e "  5. Infrastructure as Code"
echo ""
sleep 3

echo -e "${YELLOW} Étape 1: Vérification de l'infrastructure${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}" | head -10
echo ""
sleep 3

echo -e "${YELLOW} Étape 2: Lancement des services WOW${NC}"
make wow-up
sleep 5

echo -e "${YELLOW} Étape 3: Test de charge pour voir les métriques${NC}"
echo -e "${GREEN}Génération de trafic sur l'application...${NC}"

# Simuler du trafic
for i in {1..50}; do
  curl -s https://app.localhost:8443 > /dev/null 2>&1 &
  curl -s https://api.localhost:8443 > /dev/null 2>&1 &
done

echo -e "${GREEN} Trafic généré !${NC}"
echo ""
sleep 3

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Points forts de l'infrastructure :${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN} Haute disponibilité${NC} - Load balancing avec Traefik"
echo -e "${GREEN} Sécurité renforcée${NC} - Vault pour les secrets + TLS partout"
echo -e "${GREEN} Observabilité complète${NC} - Logs, métriques, traces"
echo -e "${GREEN} GitOps ready${NC} - Infrastructure as Code"
echo -e "${GREEN} Scalabilité${NC} - Architecture microservices"
echo -e "${GREEN} Monitoring temps réel${NC} - 7 outils de monitoring"
echo ""
sleep 3

echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE} Dashboards disponibles :${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Grafana${NC}       : https://grafana.localhost:8443"
echo -e "  ${CYAN}Dozzle Logs${NC}   : https://logs.localhost:8443"
echo -e "  ${CYAN}Jaeger${NC}        : https://jaeger.localhost:8443"
echo -e "  ${CYAN}Vault UI${NC}      : https://vault-ui.localhost:8443"
echo -e "  ${CYAN}Portainer${NC}     : https://portainer.localhost:8443"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN} Démonstration prête !${NC}"
echo -e "${YELLOW}Ouvrez les dashboards dans votre navigateur pour l'effet WOW !${NC}"