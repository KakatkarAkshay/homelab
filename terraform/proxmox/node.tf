resource "proxmox_network_linux_bridge" "management" {
  for_each = var.proxmox_nodes

  node_name  = each.key
  name       = "vmbr0"
  ports      = ["nic0"]
  vlan_aware = true
  vids       = join(" ", sort([tostring(var.proxmox_iot_vlan), tostring(var.proxmox_management_vlan)]))
}

resource "proxmox_network_linux_vlan" "management" {
  for_each = var.proxmox_nodes

  node_name = each.key
  name      = "vmbr0.${var.proxmox_management_vlan}"
  address   = each.value.bridge_address
  gateway   = var.proxmox_bridge_gateway
}

# Storage definitions are cluster-wide; both nodes share the pve/data thin pool layout.
resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["backup", "import", "iso", "vztmpl"]
  shared  = false
}

resource "proxmox_storage_lvmthin" "local_lvm" {
  id           = "local-lvm"
  volume_group = "pve"
  thin_pool    = "data"
  content      = ["images", "rootdir"]
}

resource "proxmox_hardware_mapping_pci" "intel_igpu" {
  name             = "intel-igpu"
  comment          = "Intel integrated GPU"
  mediated_devices = false

  map = [for node, gpu in var.proxmox_igpus : {
    id           = gpu.pci_id
    iommu_group  = gpu.iommu_group
    node         = node
    path         = gpu.pci_path
    subsystem_id = gpu.subsystem_id
  }]

  lifecycle {
    precondition {
      condition     = alltrue([for node in keys(var.proxmox_igpus) : contains(keys(var.proxmox_nodes), node)])
      error_message = "Every key in proxmox_igpus must also be a key in proxmox_nodes."
    }
  }
}
