# Create virtual network for K8s infrastructure
resource "libvirt_network" "k8s_network" {
  name      = "k8s-network"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = [var.network_cidr]
  autostart = true

  dns {
    enabled = true
  }

  dhcp {
    enabled = false
  }
}
