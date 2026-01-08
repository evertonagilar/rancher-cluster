terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

locals {
  # Parse IP to get base and starting octet
  ip_parts    = split(".", var.ip_start)
  ip_base     = join(".", slice(local.ip_parts, 0, 3))
  ip_start_num = tonumber(local.ip_parts[3])
}

module "nodes" {
  source = "../libvirt-vm"
  
  count = var.node_count

  name            = "${var.cluster_name}-${count.index + 1}"
  hostname        = "${var.cluster_name}-${count.index + 1}"
  memory          = var.memory
  vcpus           = var.vcpus
  ip              = "${local.ip_base}.${local.ip_start_num + count.index}"
  network_id      = var.network_id
  ssh_keys        = var.ssh_keys
  base_image_url  = var.base_image_url
}
