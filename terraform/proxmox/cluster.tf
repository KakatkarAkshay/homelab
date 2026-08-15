locals {
  cluster_versions  = jsondecode(file("${path.module}/../../cluster-versions.json"))
  control_plane_key = one([for k, n in var.cluster_nodes : k if n.role == "controlplane"])
  control_plane_ip  = split("/", var.cluster_nodes[local.control_plane_key].address)[0]
  cluster_endpoint  = "https://${local.control_plane_ip}:6443"
  management_subnet = var.management_subnet
}

resource "talos_machine_secrets" "this" {
  talos_version = local.cluster_versions.talos
}

resource "random_pet" "node" {
  for_each = var.cluster_nodes

  length = 2
}

resource "talos_image_factory_schematic" "this" {
  schematic = file("${path.module}/talos-schematic.yaml")
}

data "talos_image_factory_urls" "this" {
  talos_version = local.cluster_versions.talos
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = "amd64"
}

resource "proxmox_download_file" "talos" {
  for_each = var.cluster_nodes

  content_type = "iso"
  datastore_id = proxmox_storage_directory.local.id
  node_name    = each.value.host
  url          = data.talos_image_factory_urls.this.urls.iso
  file_name    = "talos-${local.cluster_versions.talos}-${talos_image_factory_schematic.this.id}-amd64.iso"
  overwrite    = false
}

data "proxmox_virtual_environment_node" "host" {
  for_each = toset([for n in var.cluster_nodes : n.host])

  node_name = each.key
}

resource "proxmox_virtual_environment_vm" "node" {
  for_each = var.cluster_nodes

  name        = random_pet.node[each.key].id
  description = "Talos ${each.value.role} on ${each.value.host}"
  tags        = ["kubernetes", "talos", "terraform", each.value.role]

  node_name = each.value.host
  bios      = each.value.bios
  machine   = each.value.machine
  started   = true
  on_boot   = true

  agent {
    enabled = true
    trim    = true
  }

  cpu {
    cores = data.proxmox_virtual_environment_node.host[each.value.host].cpu_count
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  dynamic "efi_disk" {
    for_each = each.value.bios == "ovmf" ? [1] : []
    content {
      datastore_id = proxmox_storage_lvmthin.local_lvm.id
      type         = "4m"
    }
  }

  cdrom {
    file_id   = proxmox_download_file.talos[each.key].id
    interface = "ide0"
  }

  disk {
    datastore_id = proxmox_storage_lvmthin.local_lvm.id
    interface    = "scsi0"
    cache        = "none"
    discard      = "on"
    file_format  = "raw"
    size         = each.value.disk
  }

  initialization {
    datastore_id = proxmox_storage_lvmthin.local_lvm.id
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = each.value.address
        gateway = var.proxmox_bridge_gateway
      }
    }
  }

  network_device {
    bridge  = proxmox_network_linux_bridge.management[each.value.host].name
    model   = "virtio"
    vlan_id = var.proxmox_management_vlan
  }

  network_device {
    bridge      = proxmox_network_linux_bridge.management[each.value.host].name
    model       = "virtio"
    vlan_id     = var.proxmox_lb_vlan
    mac_address = each.value.lb_mac
  }

  network_device {
    bridge      = proxmox_network_linux_bridge.management[each.value.host].name
    model       = "virtio"
    vlan_id     = var.proxmox_iot_vlan
    mac_address = each.value.iot_mac
  }

  dynamic "hostpci" {
    for_each = each.value.gpu && !each.value.legacy_igd ? [1] : []
    content {
      device  = "hostpci0"
      mapping = proxmox_hardware_mapping_pci.intel_igpu.name
      pcie    = true
      rombar  = true
    }
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = each.value.legacy_igd ? "none" : "serial0"
  }

  boot_order      = ["scsi0", "ide0"]
  scsi_hardware   = "virtio-scsi-pci"
  stop_on_destroy = true

  lifecycle {
    ignore_changes = [initialization[0].user_account, vga, hostpci]
  }
}

# legacy-igd (Gen7 HD 4000 must appear at guest 00:02.0) is not expressible in bpg hostpci; set via qm.
resource "terraform_data" "legacy_igd" {
  for_each = { for k, n in var.cluster_nodes : k => n if n.gpu && n.legacy_igd }

  triggers_replace = [proxmox_virtual_environment_vm.node[each.key].vm_id]

  provisioner "local-exec" {
    command = join(" ", [
      "ssh -o StrictHostKeyChecking=accept-new ${var.proxmox_ssh_user}@${split("/", var.proxmox_nodes[each.value.host].bridge_address)[0]}",
      "'qm set ${proxmox_virtual_environment_vm.node[each.key].vm_id} --vga none",
      "--hostpci0 ${var.proxmox_igpus[each.value.host].pci_path},legacy-igd=1 &&",
      "qm reboot ${proxmox_virtual_environment_vm.node[each.key].vm_id}'",
    ])
  }
}

data "talos_machine_configuration" "this" {
  for_each = var.cluster_nodes

  cluster_name       = var.cluster_name
  machine_type       = each.value.role
  cluster_endpoint   = local.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = local.cluster_versions.talos
  kubernetes_version = local.cluster_versions.kubernetes
}

resource "talos_machine_configuration_apply" "node" {
  for_each = var.cluster_nodes

  depends_on = [proxmox_virtual_environment_vm.node, terraform_data.legacy_igd]

  node                        = split("/", each.value.address)[0]
  endpoint                    = split("/", each.value.address)[0]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.this.urls.installer
          disk  = "/dev/sda"
        }
        kernel = {
          modules = each.value.gpu ? [{ name = "i915" }] : []
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
          }
          nodeIP = {
            validSubnets = [local.management_subnet]
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              type        = "bind"
              source      = "/var/lib/longhorn"
              options     = ["bind", "rshared", "rw"]
            },
          ]
        }
        network = {
          interfaces = [
            {
              deviceSelector = { hardwareAddr = lower(each.value.lb_mac) }
              dhcp           = false
              addresses      = [each.value.lb_address]
            },
            {
              deviceSelector = { hardwareAddr = lower(each.value.iot_mac) }
              dhcp           = false
            },
          ]
        }
        nodeLabels = each.value.gpu ? {
          "intel.feature.node.kubernetes.io/gpu" = "true"
        } : {}
        time = {
          servers = ["time.cloudflare.com"]
        }
      }
      cluster = merge(
        {
          network = {
            podSubnets     = var.kubernetes_pod_subnets
            serviceSubnets = var.kubernetes_service_subnets
          }
          apiServer = {
            extraArgs = {
              oidc-client-id       = "kubernetes"
              oidc-groups-claim    = "groups"
              oidc-groups-prefix   = "authentik:"
              oidc-issuer-url      = "https://auth.kakatkarakshay.dev/application/o/kubernetes/"
              oidc-username-claim  = "preferred_username"
              oidc-username-prefix = "authentik:"
            }
          }
        },
        each.value.role == "controlplane" ? {
          allowSchedulingOnControlPlanes = true
        } : {},
      )
    }),
  ]

  timeouts = {
    create = "25m"
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.node]

  node                 = local.control_plane_ip
  endpoint             = local.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  node                 = local.control_plane_ip
  endpoint             = local.control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.control_plane_ip]
}
