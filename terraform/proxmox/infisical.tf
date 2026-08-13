resource "infisical_project" "homelab" {
  name = "Homelab"
  slug = "homelab"
}

resource "infisical_identity" "external_secrets" {
  name   = "homelab-eso"
  org_id = var.infisical_org_id
  role   = "no-access"
}

resource "infisical_project_identity" "external_secrets" {
  project_id     = infisical_project.homelab.id
  identity_id    = infisical_identity.external_secrets.id
  adopt_existing = true

  roles = [
    { role_slug = "viewer" },
  ]
}

resource "infisical_identity_universal_auth" "external_secrets" {
  identity_id = infisical_identity.external_secrets.id
}

resource "infisical_identity_universal_auth_client_secret" "external_secrets" {
  depends_on = [infisical_identity_universal_auth.external_secrets]

  identity_id = infisical_identity.external_secrets.id
  description = "external-secrets operator"
}

resource "kubernetes_secret_v1" "infisical_eso" {
  depends_on = [flux_bootstrap_git.this]

  metadata {
    name      = "infisical-universal-auth"
    namespace = "flux-system"
  }

  data = {
    clientId     = infisical_identity_universal_auth_client_secret.external_secrets.client_id
    clientSecret = infisical_identity_universal_auth_client_secret.external_secrets.client_secret
  }
}

resource "infisical_secret_folder" "newt" {
  project_id       = infisical_project.homelab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "newt"
  description      = "Newt site credentials issued by Pangolin."
}

resource "infisical_secret" "newt_pangolin_endpoint" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.newt.path
  name         = "PANGOLIN_ENDPOINT"
  value        = var.newt_pangolin_endpoint
}

resource "infisical_secret" "newt_id" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.newt.path
  name         = "NEWT_ID"
  value        = var.newt_id
}

resource "infisical_secret" "newt_secret" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.newt.path
  name         = "NEWT_SECRET"
  value        = var.newt_secret
}
