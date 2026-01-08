variable "name" {
  description = "Name of the VM"
  type        = string
}

variable "hostname" {
  description = "Hostname of the VM"
  type        = string
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "vcpus" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2
}

variable "ip" {
  description = "Static IP address"
  type        = string
}

variable "network_id" {
  description = "Libvirt network ID"
  type        = string
}

variable "ssh_keys" {
  description = "List of SSH public keys"
  type        = list(string)
  default     = []
}

variable "cloud_init_extra" {
  description = "Additional cloud-init configuration"
  type        = string
  default     = ""
}

variable "base_image_url" {
  description = "URL of the base image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "disk_size" {
  description = "Disk size in bytes"
  type        = number
  default     = 21474836480 # 20GB
}
