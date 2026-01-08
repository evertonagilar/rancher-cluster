# RKE2 Production Cluster
module "rke2_cluster" {
  source = "../../modules/k8s-cluster"
  
  count = var.enable_rke2 ? 1 : 0

  cluster_name = "rke2-node"
  node_count   = var.rke2_node_count
  memory       = var.rke2_memory
  vcpus        = var.rke2_vcpus
  ip_start     = var.rke2_ip_start
  network_id   = libvirt_network.k8s_network.id
  ssh_keys     = var.ssh_public_keys
}
