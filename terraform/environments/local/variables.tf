variable "domain" {
  description = "Base domain for the infrastructure"
  type        = string
  default     = "arq.unb.br"
}

variable "network_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "192.168.56.0/24"
}

variable "ssh_public_keys" {
  description = "List of SSH public keys to add to VMs"
  type        = list(string)
  default     = []
}

# Rancher configuration
variable "rancher_memory" {
  description = "Memory for Rancher VM in MB"
  type        = number
  default     = 4096
}

variable "rancher_vcpus" {
  description = "vCPUs for Rancher VM"
  type        = number
  default     = 2
}

variable "rancher_ip" {
  description = "IP address for Rancher VM"
  type        = string
  default     = "192.168.56.101"
}

# Vault configuration
variable "vault_memory" {
  description = "Memory for Vault VM in MB"
  type        = number
  default     = 4096
}

variable "vault_vcpus" {
  description = "vCPUs for Vault VM"
  type        = number
  default     = 2
}

variable "vault_ip" {
  description = "IP address for Vault VM"
  type        = string
  default     = "192.168.56.102"
}

# OpenLDAP configuration
variable "openldap_memory" {
  description = "Memory for OpenLDAP VM in MB"
  type        = number
  default     = 2048
}

variable "openldap_vcpus" {
  description = "vCPUs for OpenLDAP VM"
  type        = number
  default     = 2
}

variable "openldap_ip" {
  description = "IP address for OpenLDAP VM"
  type        = string
  default     = "192.168.56.100"
}

# RKE2 configuration
variable "rke2_node_count" {
  description = "Number of RKE2 nodes"
  type        = number
  default     = 3
}

variable "rke2_memory" {
  description = "Memory for each RKE2 node in MB"
  type        = number
  default     = 4096
}

variable "rke2_vcpus" {
  description = "vCPUs for each RKE2 node"
  type        = number
  default     = 2
}

variable "rke2_ip_start" {
  description = "Starting IP address for RKE2 nodes"
  type        = string
  default     = "192.168.56.110"
}

# Enable/disable components
variable "enable_rancher" {
  description = "Enable Rancher VM provisioning"
  type        = bool
  default     = true
}

variable "enable_vault" {
  description = "Enable Vault VM provisioning"
  type        = bool
  default     = true
}

variable "enable_openldap" {
  description = "Enable OpenLDAP VM provisioning"
  type        = bool
  default     = true
}

variable "enable_rke2" {
  description = "Enable RKE2 cluster provisioning"
  type        = bool
  default     = true
}
