locals {
  endpoint = "https://${split("/", var.proxmox_nodes[var.proxmox_api_node].bridge_address)[0]}:8006"
}

provider "proxmox" {
  endpoint  = local.endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}
