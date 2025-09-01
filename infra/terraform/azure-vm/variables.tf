variable "project" {
  description = "Project/name prefix"
  type        = string
  default     = "cia"
}

variable "subscription_id" {
  description = "Azure Subscription ID to deploy into"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "vnet_cidr" {
  description = "VNet CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH to the VM"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gitea_ssh_port" {
  description = "Host port exposed for Gitea SSH"
  type        = number
  default     = 2222
}

variable "allowed_gitea_ssh_cidrs" {
  description = "CIDRs allowed to access Gitea SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "git_repo_url" {
  description = "Optional Git repository to clone on the VM"
  type        = string
  default     = ""
}

variable "git_repo_branch" {
  description = "Optional branch to checkout"
  type        = string
  default     = "main"
}

variable "acme_email" {
  description = "Let's Encrypt contact email passed to Ansible to generate .env"
  type        = string
  default     = "admin@example.com"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

variable "auto_deploy_apps" {
  description = "Automatically deploy Docker applications on VM creation using Ansible"
  type        = bool
  default     = true
}
