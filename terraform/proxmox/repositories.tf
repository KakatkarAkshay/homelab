resource "proxmox_apt_standard_repository" "no_subscription" {
  for_each = var.proxmox_nodes

  node   = each.key
  handle = "no-subscription"
}

resource "proxmox_apt_repository" "no_subscription" {
  for_each = var.proxmox_nodes

  node      = each.key
  file_path = proxmox_apt_standard_repository.no_subscription[each.key].file_path
  index     = proxmox_apt_standard_repository.no_subscription[each.key].index
  enabled   = true
}

locals {
  disabled_enterprise_repos = merge([
    for node, paths in var.proxmox_enterprise_repos : {
      for path in paths : "${node}:${path}" => { node = node, file_path = path }
    }
  ]...)
}

resource "proxmox_apt_repository" "enterprise_disabled" {
  for_each = local.disabled_enterprise_repos

  node      = each.value.node
  file_path = each.value.file_path
  index     = 0
  enabled   = false
}
