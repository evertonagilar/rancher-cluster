output "node_ips" {
  description = "List of node IP addresses"
  value       = module.nodes[*].ip
}

output "node_names" {
  description = "List of node names"
  value       = module.nodes[*].name
}

output "node_ids" {
  description = "List of node domain IDs"
  value       = module.nodes[*].id
}
