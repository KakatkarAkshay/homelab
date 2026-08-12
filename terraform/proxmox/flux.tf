resource "tls_private_key" "flux" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "flux" {
  repository = var.github_repository
  title      = "flux-homelab-terraform"
  key        = trimspace(tls_private_key.flux.public_key_openssh)
  read_only  = false
}

resource "flux_bootstrap_git" "this" {
  depends_on = [talos_cluster_kubeconfig.this, github_repository_deploy_key.flux]

  embedded_manifests = true
  path               = "kubernetes/clusters/homelab"
}
