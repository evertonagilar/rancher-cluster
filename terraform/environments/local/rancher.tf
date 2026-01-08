# Rancher Management Server
module "rancher" {
  source = "../../modules/libvirt-vm"
  
  count = var.enable_rancher ? 1 : 0

  name       = "rancher-server"
  hostname   = "rancher-server"
  memory     = var.rancher_memory
  vcpus      = var.rancher_vcpus
  ip         = var.rancher_ip
  network_id = libvirt_network.k8s_network.id
  ssh_keys   = var.ssh_public_keys
}
