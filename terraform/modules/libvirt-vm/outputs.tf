output "id" {
  description = "VM domain ID"
  value       = libvirt_domain.vm.id
}

output "ip" {
  description = "VM IP address"
  value       = var.ip
}

output "name" {
  description = "VM name"
  value       = var.name
}

output "hostname" {
  description = "VM hostname"
  value       = var.hostname
}
