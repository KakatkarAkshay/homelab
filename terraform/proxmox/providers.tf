locals {
  endpoint = "https://${split("/", var.proxmox_nodes[var.proxmox_api_node].bridge_address)[0]}:8006"
}

provider "proxmox" {
  endpoint  = local.endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
}

provider "flux" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  }

  git = {
    url    = "ssh://git@github.com/${var.github_owner}/${var.github_repository}.git"
    branch = "main"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_openssh
    }
  }
}

# Reads GITHUB_TOKEN from the environment.
provider "github" {
  owner = var.github_owner
}

# Universal Auth locally (INFISICAL_UNIVERSAL_AUTH_CLIENT_ID/SECRET), OIDC in CI
# (INFISICAL_MACHINE_IDENTITY_ID + INFISICAL_AUTH_JWT). The OIDC method is created by hand in Infisical.
provider "infisical" {
  host = var.infisical_host
  auth = {
    oidc      = var.infisical_auth_method == "oidc" ? {} : null
    universal = var.infisical_auth_method == "universal" ? {} : null
  }
}

provider "cloudflare" {
  api_token = data.terraform_remote_state.cloudlab.outputs.cloudflare_api_token
}
