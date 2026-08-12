variable "cluster_name" {
  description = "Talos/Kubernetes cluster name."
  type        = string
  default     = "homelab"
}

variable "kubernetes_pod_subnets" {
  description = "Pod CIDR ranges."
  type        = list(string)
  default     = ["10.244.0.0/16"]
}

variable "kubernetes_service_subnets" {
  description = "Service CIDR ranges."
  type        = list(string)
  default     = ["10.96.0.0/12"]
}

variable "cluster_nodes" {
  description = "Talos VMs, keyed by logical id. host is the Proxmox node; gpu passes that host's Intel iGPU through. legacy_igd is required for the Gen7 HD 4000 (needs i440fx/SeaBIOS/vga none)."
  type = map(object({
    host       = string
    role       = string
    address    = string
    lb_address = string
    lb_mac     = string
    memory     = number
    disk       = number
    gpu        = bool
    machine    = string
    bios       = string
    legacy_igd = bool
  }))

  default = {
    cp = {
      host       = "pve"
      role       = "controlplane"
      address    = "192.168.20.10/24"
      lb_address = "192.168.30.2/24"
      lb_mac     = "bc:24:11:30:00:10"
      memory     = 12288
      disk       = 1700
      gpu        = true
      machine    = "q35"
      bios       = "ovmf"
      legacy_igd = false
    }
    worker = {
      host       = "pve-mac"
      role       = "worker"
      address    = "192.168.20.11/24"
      lb_address = "192.168.30.3/24"
      lb_mac     = "bc:24:11:30:00:11"
      memory     = 12288
      disk       = 320
      gpu        = true
      machine    = "pc"
      bios       = "seabios"
      legacy_igd = true
    }
  }

  validation {
    condition     = length([for n in var.cluster_nodes : n if n.role == "controlplane"]) == 1
    error_message = "Exactly one node must have role controlplane."
  }

  validation {
    condition     = alltrue([for n in var.cluster_nodes : contains(["controlplane", "worker"], n.role)])
    error_message = "role must be controlplane or worker."
  }

  validation {
    condition     = alltrue([for n in var.cluster_nodes : can(cidrnetmask(n.address))])
    error_message = "Every node address must be an IPv4 CIDR."
  }
}

variable "management_subnet" {
  description = "CIDR of the management VLAN, used for Talos kubelet nodeIP selection."
  type        = string
  default     = "192.168.20.0/24"

  validation {
    condition     = can(cidrnetmask(var.management_subnet))
    error_message = "management_subnet must be an IPv4 CIDR."
  }
}

variable "proxmox_ssh_user" {
  description = "SSH user on the Proxmox hosts, used to apply legacy-igd via qm set."
  type        = string
  default     = "root"
}

variable "proxmox_lb_vlan" {
  description = "VLAN carrying MetalLB LoadBalancer VIPs; nodes get a leg here for L2 announcement."
  type        = number
  default     = 30

  validation {
    condition     = var.proxmox_lb_vlan >= 1 && var.proxmox_lb_vlan <= 4094
    error_message = "proxmox_lb_vlan must be between 1 and 4094."
  }
}

variable "github_owner" {
  description = "GitHub account that owns the homelab repository."
  type        = string
  default     = "KakatkarAkshay"
}

variable "github_repository" {
  description = "Name of the homelab GitHub repository."
  type        = string
  default     = "homelab"
}
