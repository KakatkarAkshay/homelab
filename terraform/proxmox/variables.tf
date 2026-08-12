variable "proxmox_api_token" {
  description = "Proxmox VE API token in user@realm!tokenid=uuid form."
  type        = string
  sensitive   = true
}

variable "proxmox_nodes" {
  description = "Cluster nodes keyed by node name, with the IPv4 CIDR each carries on the management VLAN."
  type = map(object({
    bridge_address = string
  }))

  default = {
    pve = {
      bridge_address = "192.168.20.2/24"
    }
    pve-mac = {
      bridge_address = "192.168.20.3/24"
    }
  }

  validation {
    condition     = alltrue([for node in var.proxmox_nodes : can(cidrnetmask(node.bridge_address))])
    error_message = "Every bridge_address must be an IPv4 CIDR, e.g. 192.168.20.2/24."
  }

  validation {
    condition     = length(var.proxmox_nodes) > 0
    error_message = "proxmox_nodes must contain at least one node."
  }
}

variable "proxmox_enterprise_repos" {
  description = "Enterprise apt source files to keep disabled, per node. Fresh installs ship these enabled and error without a subscription."
  type        = map(list(string))

  default = {
    pve-mac = [
      "/etc/apt/sources.list.d/pve-enterprise.sources",
      "/etc/apt/sources.list.d/ceph.sources",
    ]
  }

  validation {
    condition     = alltrue([for node in keys(var.proxmox_enterprise_repos) : contains(keys(var.proxmox_nodes), node)])
    error_message = "Every key in proxmox_enterprise_repos must be a key in proxmox_nodes."
  }
}

variable "proxmox_api_node" {
  description = "Node whose management address the provider connects to. Any cluster member can serve the whole cluster."
  type        = string
  default     = "pve"

  validation {
    condition     = length(var.proxmox_api_node) > 0
    error_message = "proxmox_api_node must not be empty."
  }
}

variable "proxmox_bridge_gateway" {
  description = "Default gateway reachable over the management VLAN."
  type        = string
  default     = "192.168.20.1"

  validation {
    condition     = can(cidrhost("${var.proxmox_bridge_gateway}/32", 0))
    error_message = "proxmox_bridge_gateway must be a valid IPv4 address."
  }
}

variable "proxmox_management_vlan" {
  description = "VLAN carrying Proxmox management traffic."
  type        = number
  default     = 20

  validation {
    condition     = var.proxmox_management_vlan >= 1 && var.proxmox_management_vlan <= 4094
    error_message = "proxmox_management_vlan must be between 1 and 4094."
  }
}

variable "proxmox_iot_vlan" {
  description = "VLAN carrying IoT devices."
  type        = number
  default     = 10

  validation {
    condition     = var.proxmox_iot_vlan >= 1 && var.proxmox_iot_vlan <= 4094
    error_message = "proxmox_iot_vlan must be between 1 and 4094."
  }
}

variable "proxmox_igpus" {
  description = "Intel iGPU on each node, published as a single cluster-wide hardware mapping."
  type = map(object({
    pci_id       = string
    pci_path     = string
    iommu_group  = number
    subsystem_id = string
  }))

  default = {
    pve = {
      pci_id       = "8086:46d4" # Alder Lake-N
      pci_path     = "0000:00:02.0"
      iommu_group  = 0
      subsystem_id = "1043:88e8"
    }
    pve-mac = {
      pci_id       = "8086:0166" # 3rd Gen Core, HD 4000
      pci_path     = "0000:00:02.0"
      iommu_group  = 0
      subsystem_id = "106b:00ff"
    }
  }

  validation {
    condition     = alltrue([for gpu in var.proxmox_igpus : can(regex("^[0-9a-f]{4}:[0-9a-f]{4}$", gpu.pci_id))])
    error_message = "Every pci_id must be lowercase vendor:device hex, e.g. 8086:46d4."
  }

  validation {
    condition     = alltrue([for gpu in var.proxmox_igpus : can(regex("^[0-9a-f]{4}:[0-9a-f]{4}$", gpu.subsystem_id))])
    error_message = "Every subsystem_id must be lowercase vendor:device hex, e.g. 1043:88e8."
  }
}
