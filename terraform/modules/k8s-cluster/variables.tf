variable "cluster_name" {
  description = "Name prefix for cluster nodes"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 3
}

variable "memory" {
  description = "Memory in MB per node"
  type        = number
  default     = 4096
}

variable "vcpus" {
  description = "Number of virtual CPUs per node"
  type        = number
  default     = 2
}

variable "ip_start" {
  description = "Starting IP address (will increment for each node)"
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

variable "base_image_url" {
  description = "URL of the base image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
