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

data "azurerm_resource_group" "existing" {
  count = var.existing_resource_group_name != "" ? 1 : 0
  name  = var.existing_resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.existing_resource_group_name == "" ? 1 : 0
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

locals {
  rg_name     = var.existing_resource_group_name != "" ? data.azurerm_resource_group.existing[0].name : azurerm_resource_group.rg[0].name
  rg_location = var.existing_resource_group_name != "" ? data.azurerm_resource_group.existing[0].location : azurerm_resource_group.rg[0].location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = local.rg_location
  resource_group_name = local.rg_name
  tags                = local.tags

  subnet {
    name             = "default"
    address_prefixes = [var.subnet_cidr]
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.name}-pip"
  location            = local.rg_location
  resource_group_name = local.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name}-nsg"
  location            = local.rg_location
  resource_group_name = local.rg_name

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
      name                       = "Allow-SSH-${replace(replace(security_rule.value, "/", "-"), ".", "-") }"
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
      name                       = "Allow-Gitea-SSH-${replace(replace(security_rule.value, "/", "-"), ".", "-") }"
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
    ignore_changes        = [tags["managed_by"]]
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.name}-nic"
  location            = local.rg_location
  resource_group_name = local.rg_name

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
  location            = local.rg_location
  resource_group_name = local.rg_name
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

  custom_data = null
  tags        = local.tags
}

resource "null_resource" "ansible_provisioner" {
  count = var.auto_deploy_apps ? 1 : 0
  depends_on = [
    azurerm_linux_virtual_machine.vm,
    azurerm_network_interface_security_group_association.nsg_assoc
  ]

  triggers = {
    vm_id     = azurerm_linux_virtual_machine.vm.id
    vm_ip     = azurerm_public_ip.pip.ip_address
    username  = var.admin_username
    play_hash = filesha256("${path.module}/../ansible/site.yml")
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<EOT
set -euo pipefail
IP=${azurerm_public_ip.pip.ip_address}
USER=${var.admin_username}
ANSIBLE_DIR="${path.module}/../ansible"

echo "Waiting for SSH availability on $IP..."
for i in {1..60}; do
  if ssh -i ${var.ansible_ssh_private_key_file} -o ConnectTimeout=5 -o StrictHostKeyChecking=no $USER@$IP 'echo ok' 2>/dev/null; then
    echo "SSH is ready"; break
  fi
  echo "Attempt $i/60: VM not ready yet..."; sleep 5
done

echo "Installing Ansible collections..."
ansible-galaxy collection install -r "$ANSIBLE_DIR/requirements.yml"

echo "Running Ansible playbook..."
ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook -i "$IP," -u "$USER" "$ANSIBLE_DIR/site.yml" \
  -e acme_email=${var.acme_email}
EOT
  }
}
