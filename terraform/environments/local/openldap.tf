# OpenLDAP Authentication Server
module "openldap" {
  source = "../../modules/libvirt-vm"
  
  count = var.enable_openldap ? 1 : 0

  name       = "openldap-server"
  hostname   = "openldap-server"
  memory     = var.openldap_memory
  vcpus      = var.openldap_vcpus
  ip         = var.openldap_ip
  network_id = libvirt_network.k8s_network.id
  ssh_keys   = var.ssh_public_keys
}
