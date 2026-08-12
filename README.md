# homelab

Home-side infrastructure: the Proxmox hosts on the LAN and the Kubernetes cluster running on them.

The OCI-hosted cluster and its Terraform live separately in
[cloudlab](https://github.com/KakatkarAkshay/cloudlab).

## Layout

```
terraform/proxmox/   Proxmox VE host configuration (network, storage, repositories, PCI mappings)
kubernetes/          Flux tree for the home cluster
  apps/
  clusters/
  infrastructure/
  observability/
```

## Nodes

| Node      | Address        | Hardware                     | Notes                     |
| --------- | -------------- | ---------------------------- | ------------------------- |
| `pve`     | `192.168.20.2` | Intel N150                   | iGPU passed through        |
| `pve-mac` | `192.168.20.3` | Late 2012 Mac Mini, i5-3210M | 2 cores / 4 threads        |

Both sit on VLAN 20 (management), reached through trunk ports on the router. Each host runs
`vmbr0` as a vlan-aware bridge carrying VLAN 10 (IoT) and VLAN 20, with the management address on
`vmbr0.20`.

## State

Terraform state is held in OCI Object Storage, not in this repo. Backend credentials are supplied
at `terraform init` time via `-backend-config`; see the workflow in `.github/workflows/`.

## CI

`terraform.yml` plans on pull requests and applies on pushes to `main`. The runner joins Tailscale
to reach the home network, so these repository secrets and variables must be set:

| Kind     | Name                                                                                                            |
| -------- | --------------------------------------------------------------------------------------------------------------- |
| Secrets  | `TF_VAR_PROXMOX_API_TOKEN`, `TF_VAR_OCI_PRIVATE_KEY`, `TF_VAR_TENANCY_1_OCID`, `TF_VAR_TENANCY_1_USER_OCID`, `TAILSCALE_OAUTH_CLIENT_ID` |
| Variables | `TF_VAR_OCI_FINGERPRINT`, `TAILSCALE_AUDIENCE`                                                                  |
