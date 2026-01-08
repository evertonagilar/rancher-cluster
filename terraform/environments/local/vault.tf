# HashiCorp Vault Server
module "vault" {
  source = "../../modules/libvirt-vm"
  
  count = var.enable_vault ? 1 : 0

  name       = "vault-server"
  hostname   = "vault-server"
  memory     = var.vault_memory
  vcpus      = var.vault_vcpus
  ip         = var.vault_ip
  network_id = libvirt_network.k8s_network.id
  ssh_keys   = var.ssh_public_keys
}
