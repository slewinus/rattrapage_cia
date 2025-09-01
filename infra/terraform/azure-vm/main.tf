terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
  # If unset, provider tries to infer from Azure CLI / env vars
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

locals {
  name = "${var.project}-${var.environment}"
  tags = merge({
    project     = var.project,
    environment = var.environment,
    managed_by  = "terraform"
  }, var.tags)
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  subnet {
    name           = "default"
    address_prefixes = [var.subnet_cidr]
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.allowed_ssh_cidrs
    content {
      name                       = "Allow-SSH-${replace(replace(security_rule.value, "/", "-"), ".", "-")}"
      priority                   = 200 + index(var.allowed_ssh_cidrs, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.allowed_gitea_ssh_cidrs
    content {
      name                       = "Allow-Gitea-SSH-${replace(replace(security_rule.value, "/", "-"), ".", "-")}"
      priority                   = 300 + index(var.allowed_gitea_ssh_cidrs, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(var.gitea_ssh_port)
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags["managed_by"]]
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = one(azurerm_virtual_network.vnet.subnet).id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = local.tags
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${local.name}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  # No cloud-init, everything via Ansible
  custom_data = null
  tags        = local.tags
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "ssh" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

locals {
  ip_dash = replace(azurerm_public_ip.pip.ip_address, ".", "-")
}

output "suggested_hosts" {
  value = {
    app      = "app.${local.ip_dash}.sslip.io"
    api      = "api.${local.ip_dash}.sslip.io"
    grafana  = "grafana.${local.ip_dash}.sslip.io"
    portainer= "portainer.${local.ip_dash}.sslip.io"
    gitea    = "gitea.${local.ip_dash}.sslip.io"
    traefik  = "traefik.${local.ip_dash}.sslip.io"
  }
}

resource "null_resource" "ansible_provisioner" {
  count = var.auto_deploy_apps ? 1 : 0
  depends_on = [
    azurerm_linux_virtual_machine.vm,
    azurerm_network_interface_security_group_association.nsg_assoc
  ]
  
  triggers = {
    vm_id = azurerm_linux_virtual_machine.vm.id
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================"
      echo "Starting Ansible deployment..."
      echo "======================================"
      
      # Wait for VM to be ready
      echo "Waiting for VM to be ready..."
      for i in {1..30}; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${var.admin_username}@${azurerm_public_ip.pip.ip_address} 'echo VM ready' 2>/dev/null; then
          echo "VM is ready!"
          break
        fi
        echo "Attempt $i/30: VM not ready yet..."
        sleep 10
      done
      
      # Run Ansible playbook
      cd ${path.module}/../../ansible
      
      # Create inventory dynamically
      cat > inventory_dynamic.yml <<EOF
      all:
        hosts:
          azure-vm:
            ansible_host: ${azurerm_public_ip.pip.ip_address}
            ansible_user: ${var.admin_username}
            ansible_ssh_private_key_file: ~/.ssh/id_rsa
      EOF
      
      # Run the complete deployment playbook
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i inventory_dynamic.yml \
        playbook-full-deploy.yml \
        --extra-vars "git_repo_url='${var.git_repo_url}' git_repo_branch='${var.git_repo_branch}' acme_email='${var.acme_email}'"
      
      echo "======================================"
      echo "Deployment complete!"
      echo "======================================"
    EOT
    
    environment = {
      ANSIBLE_FORCE_COLOR = "true"
      PYTHONUNBUFFERED = "1"
    }
  }
}

output "ansible_command" {
  value = "cd ${path.module}/../../ansible && VM_PUBLIC_IP=${azurerm_public_ip.pip.ip_address} ansible-playbook -i inventory.yml site.yml"
  description = "Command to manually run Ansible deployment"
}
