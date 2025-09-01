output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh" {
  description = "SSH command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

locals {
  ip_dash = replace(azurerm_public_ip.pip.ip_address, ".", "-")
}

output "suggested_hosts" {
  description = "Suggested sslip.io hosts"
  value = {
    app       = "app.${local.ip_dash}.sslip.io"
    api       = "api.${local.ip_dash}.sslip.io"
    grafana   = "grafana.${local.ip_dash}.sslip.io"
    portainer = "portainer.${local.ip_dash}.sslip.io"
    gitea     = "gitea.${local.ip_dash}.sslip.io"
  }
}

