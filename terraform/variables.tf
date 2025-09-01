variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "location" {
  description = "Azure region (e.g., francecentral)"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (optional if using Azure CLI auth)"
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "vnet_cidr" {
  description = "VNet CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDRs allowed to SSH (port 22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gitea_ssh_port" {
  description = "Public SSH port for Gitea"
  type        = number
  default     = 2222
}

variable "allowed_gitea_ssh_cidrs" {
  description = "List of CIDRs allowed to access Gitea SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra Azure tags"
  type        = map(string)
  default     = {}
}

variable "existing_resource_group_name" {
  description = "Use an existing resource group instead of creating a new one (leave empty to create)"
  type        = string
  default     = ""
}

variable "auto_deploy_apps" {
  description = "If true, runs Ansible automatically after provisioning"
  type        = bool
  default     = false
}

variable "acme_email" {
  description = "ACME email for Let's Encrypt passed to Ansible (optional here, recommended to set)"
  type        = string
  default     = ""
}

variable "ansible_ssh_private_key_file" {
  description = "Path to SSH private key to use for Ansible"
  type        = string
  default     = "~/.ssh/id_rsa"
}
