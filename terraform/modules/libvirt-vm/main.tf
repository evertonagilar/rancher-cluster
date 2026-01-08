terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

# Create volume from base image
resource "libvirt_volume" "vm" {
  name   = "${var.name}.qcow2"
  pool   = "default"
  source = var.base_image_url
  format = "qcow2"
  size   = var.disk_size
}

# Cloud-init configuration
data "template_file" "cloud_init" {
  template = <<-EOT
    #cloud-config
    hostname: ${var.hostname}
    fqdn: ${var.hostname}.k8s.local
    manage_etc_hosts: true
    
    users:
      - name: vagrant
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: false
        passwd: $6$rounds=4096$saltsalt$IjEXPYpfN3cXXxSqZvC8K5vJz9fZ7.1qJKqKvLvKvLvKvLvKvLvKvLvKvLvKvLvKvLvKvLvKvLvKvLvKvLvK.
        ssh_authorized_keys:
          %{for key in var.ssh_keys~}
          - ${key}
          %{endfor~}
      - name: evertonagilar
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        groups: users, admin
        ssh_authorized_keys:
          %{for key in var.ssh_keys~}
          - ${key}
          %{endfor~}
    
    package_update: true
    package_upgrade: false
    
    packages:
      - qemu-guest-agent
      - python3
      - python3-pip
    
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    
    ${var.cloud_init_extra}
  EOT
}

resource "libvirt_cloudinit_disk" "vm" {
  name      = "${var.name}-cloudinit.iso"
  user_data = data.template_file.cloud_init.rendered
  pool      = "default"
}

# Create the VM
resource "libvirt_domain" "vm" {
  name   = var.name
  memory = var.memory
  vcpu   = var.vcpus

  cloudinit = libvirt_cloudinit_disk.vm.id

  network_interface {
    network_id     = var.network_id
    addresses      = [var.ip]
    hostname       = var.hostname
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  # Ensure VM starts automatically
  autostart = false
}
