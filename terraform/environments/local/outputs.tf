# Network outputs
output "network_id" {
  description = "K8s network ID"
  value       = libvirt_network.k8s_network.id
}

output "network_cidr" {
  description = "K8s network CIDR"
  value       = var.network_cidr
}

# Rancher outputs
output "rancher_ip" {
  description = "Rancher server IP address"
  value       = var.enable_rancher ? module.rancher[0].ip : null
}

output "rancher_name" {
  description = "Rancher server name"
  value       = var.enable_rancher ? module.rancher[0].name : null
}

# Vault outputs
output "vault_ip" {
  description = "Vault server IP address"
  value       = var.enable_vault ? module.vault[0].ip : null
}

output "vault_name" {
  description = "Vault server name"
  value       = var.enable_vault ? module.vault[0].name : null
}

# OpenLDAP outputs
output "openldap_ip" {
  description = "OpenLDAP server IP address"
  value       = var.enable_openldap ? module.openldap[0].ip : null
}

output "openldap_name" {
  description = "OpenLDAP server name"
  value       = var.enable_openldap ? module.openldap[0].name : null
}

# RKE2 outputs
output "rke2_node_ips" {
  description = "RKE2 cluster node IP addresses"
  value       = var.enable_rke2 ? module.rke2_cluster[0].node_ips : []
}

output "rke2_node_names" {
  description = "RKE2 cluster node names"
  value       = var.enable_rke2 ? module.rke2_cluster[0].node_names : []
}

# Summary output
output "infrastructure_summary" {
  description = "Summary of all provisioned infrastructure"
  value = {
    network = {
      cidr = var.network_cidr
    }
    rancher = var.enable_rancher ? {
      ip   = module.rancher[0].ip
      name = module.rancher[0].name
    } : null
    vault = var.enable_vault ? {
      ip   = module.vault[0].ip
      name = module.vault[0].name
    } : null
    openldap = var.enable_openldap ? {
      ip   = module.openldap[0].ip
      name = module.openldap[0].name
    } : null
    rke2 = var.enable_rke2 ? {
      node_count = var.rke2_node_count
      node_ips   = module.rke2_cluster[0].node_ips
      node_names = module.rke2_cluster[0].node_names
    } : null
  }
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventory/terraform.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    rancher_ips  = var.enable_rancher ? [module.rancher[0].ip] : []
    vault_ips    = var.enable_vault ? [module.vault[0].ip] : []
    openldap_ips = var.enable_openldap ? [module.openldap[0].ip] : []
    rke2_ips     = var.enable_rke2 ? module.rke2_cluster[0].node_ips : []
  })
}
