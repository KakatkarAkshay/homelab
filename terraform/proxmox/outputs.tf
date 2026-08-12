output "kubeconfig" {
  description = "Kubeconfig for the homelab cluster."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "node_hostnames" {
  description = "Generated hostname per cluster node."
  value       = { for k, p in random_pet.node : k => p.id }
}
