.PHONY: help init plan apply destroy deploy redeploy ssh check-services clean

TERRAFORM_DIR = terraform/azure-vm
ANSIBLE_DIR = ansible

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

help: ## Show this help message
	@echo "CIA Infrastructure Management"
	@echo "=============================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Plan infrastructure changes
	@echo "$(YELLOW)Planning infrastructure changes...$(NC)"
	cd $(TERRAFORM_DIR) && terraform plan

apply: ## Create/Update infrastructure and deploy apps with Ansible
	@echo "$(GREEN)Creating infrastructure and deploying applications with Ansible...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve
	@echo "$(GREEN)Infrastructure and applications deployed successfully!$(NC)"
	@echo ""
	@make urls

destroy: ## Destroy all infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && \
	if [ "$$confirm" = "yes" ]; then \
		cd $(TERRAFORM_DIR) && terraform destroy -auto-approve; \
	else \
		echo "Cancelled."; \
	fi

deploy: ## Deploy applications with Ansible (VM must exist)
	@echo "$(YELLOW)Deploying applications with Ansible...$(NC)"
	@VM_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw public_ip 2>/dev/null) && \
	if [ -z "$$VM_IP" ]; then \
		echo "$(RED)Error: VM not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi && \
	export VM_PUBLIC_IP=$$VM_IP && \
	export ANSIBLE_HOST_KEY_CHECKING=False && \
	cd $(ANSIBLE_DIR) && \
	ansible-playbook -i inventory.yml site.yml --extra-vars "vm_public_ip=$$VM_IP"
	@echo "$(GREEN)Applications deployed successfully!$(NC)"
	@cat /tmp/credentials.txt 2>/dev/null || true

redeploy: ## Redeploy applications (faster than full apply)
	@echo "$(YELLOW)Redeploying applications...$(NC)"
	@make deploy

ssh: ## SSH into the Azure VM
	@VM_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw public_ip 2>/dev/null) && \
	if [ -z "$$VM_IP" ]; then \
		echo "$(RED)Error: VM not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi && \
	echo "$(GREEN)Connecting to $$VM_IP...$(NC)" && \
	ssh -o StrictHostKeyChecking=no azureuser@$$VM_IP

check-services: ## Check status of deployed services
	@echo "$(YELLOW)Checking services status...$(NC)"
	@VM_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw public_ip 2>/dev/null) && \
	if [ -z "$$VM_IP" ]; then \
		echo "$(RED)Error: VM not found.$(NC)"; \
		exit 1; \
	fi && \
	IP_DASH=$$(echo $$VM_IP | sed 's/\./-/g') && \
	echo "" && \
	for service in app api grafana portainer gitea traefik; do \
		response=$$(curl -s -o /dev/null -w "%{http_code}" https://$$service.$$IP_DASH.sslip.io --max-time 5) && \
		if [ "$$response" = "200" ] || [ "$$response" = "301" ] || [ "$$response" = "302" ]; then \
			echo "$(GREEN)✓$(NC) $$service: OK ($$response)"; \
		else \
			echo "$(RED)✗$(NC) $$service: Failed ($$response)"; \
		fi; \
	done

urls: ## Show service URLs
	@VM_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw public_ip 2>/dev/null) && \
	if [ -z "$$VM_IP" ]; then \
		echo "$(RED)Error: VM not found.$(NC)"; \
		exit 1; \
	fi && \
	IP_DASH=$$(echo $$VM_IP | sed 's/\./-/g') && \
	echo "" && \
	echo "$(GREEN)Service URLs:$(NC)" && \
	echo "  Application:  https://app.$$IP_DASH.sslip.io" && \
	echo "  API:         https://api.$$IP_DASH.sslip.io" && \
	echo "  Grafana:     https://grafana.$$IP_DASH.sslip.io" && \
	echo "  Portainer:   https://portainer.$$IP_DASH.sslip.io" && \
	echo "  Gitea:       https://gitea.$$IP_DASH.sslip.io" && \
	echo "  Traefik:     https://traefik.$$IP_DASH.sslip.io" && \
	echo "" && \
	echo "$(YELLOW)SSH Access:$(NC)" && \
	echo "  ssh azureuser@$$VM_IP"

logs: ## Show Docker logs from VM
	@VM_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw public_ip 2>/dev/null) && \
	ssh -o StrictHostKeyChecking=no azureuser@$$VM_IP "docker ps && echo '' && docker compose -f /opt/cia/ops/docker-compose.yml logs --tail=50"

clean: ## Clean up local files
	@echo "$(YELLOW)Cleaning up...$(NC)"
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	rm -f $(TERRAFORM_DIR)/terraform.tfstate*
	@echo "$(GREEN)Cleanup complete!$(NC)"

install-deps: ## Install required dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@which terraform > /dev/null || (echo "Installing Terraform..." && brew install terraform)
	@which ansible > /dev/null || (echo "Installing Ansible..." && pip3 install ansible)
	@which az > /dev/null || (echo "Installing Azure CLI..." && brew install azure-cli)
	@echo "$(GREEN)All dependencies installed!$(NC)"

quick-start: install-deps init apply ## Quick start: Install deps, init, and deploy everything
	@echo "$(GREEN)Quick start complete! Your infrastructure is ready.$(NC)"
	@make urls
	@make check-services