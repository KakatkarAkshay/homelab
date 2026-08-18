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

resource "infisical_secret" "cloudflare_api_token" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/cloudflare"
  name         = "API_TOKEN"
  value        = data.terraform_remote_state.cloudlab.outputs.cloudflare_api_token
}

resource "infisical_secret" "idrive_access_key_id" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/idrive-credentials"
  name         = "ACCESS_KEY_ID"
  value        = data.terraform_remote_state.cloudlab.outputs.idrive_access_key_id
}

resource "infisical_secret" "idrive_secret_access_key" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/idrive-credentials"
  name         = "ACCESS_SECRET_KEY"
  value        = data.terraform_remote_state.cloudlab.outputs.idrive_secret_access_key
}

resource "infisical_secret" "idrive_e2_endpoint" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/idrive-credentials"
  name         = "E2_ENDPOINT"
  value        = data.terraform_remote_state.cloudlab.outputs.idrive_e2_endpoint
}

resource "infisical_secret" "idrive_aws_region" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/idrive-credentials"
  name         = "AWS_REGION"
  value        = data.terraform_remote_state.cloudlab.outputs.idrive_aws_region
}

resource "infisical_secret" "volsync_restic_password" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = "/platform/volsync"
  name         = "RESTIC_PASSWORD"
  value        = data.terraform_remote_state.cloudlab.outputs.volsync_restic_password
}

resource "infisical_secret_folder" "immich" {
  project_id       = infisical_project.homelab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "immich"
  description      = "Immich application secrets issued by cloudlab."
}

resource "infisical_secret" "immich_oauth_client_id" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.immich.path
  name         = "OAUTH_CLIENT_ID"
  value        = data.terraform_remote_state.cloudlab.outputs.immich_oauth_client_id
}

resource "infisical_secret" "immich_oauth_client_secret" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.immich.path
  name         = "OAUTH_CLIENT_SECRET"
  value        = data.terraform_remote_state.cloudlab.outputs.immich_oauth_client_secret
}

resource "infisical_secret_folder" "authentik" {
  project_id       = infisical_project.homelab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "authentik"
  description      = "Token the local outpost uses to reach authentik."
}

resource "infisical_secret" "authentik_outpost_token" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "OUTPOST_TOKEN"
  value        = var.authentik_outpost_token
}




resource "infisical_secret_folder" "thanos" {
  project_id       = infisical_project.homelab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "thanos"
  description      = "CA issued by cloudlab for authenticating writes to Thanos."
}

resource "infisical_secret" "thanos_ca_cert" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.thanos.path
  name         = "CA_CERT"
  value        = data.terraform_remote_state.cloudlab.outputs.thanos_ca_cert
}

resource "infisical_secret" "thanos_ca_key" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.thanos.path
  name         = "CA_KEY"
  value        = data.terraform_remote_state.cloudlab.outputs.thanos_ca_key
}

resource "infisical_secret_folder" "loki" {
  project_id       = infisical_project.homelab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "loki"
  description      = "CA issued by cloudlab for authenticating writes to Loki."
}

resource "infisical_secret" "loki_ca_cert" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.loki.path
  name         = "CA_CERT"
  value        = data.terraform_remote_state.cloudlab.outputs.loki_ca_cert
}

resource "infisical_secret" "loki_ca_key" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.loki.path
  name         = "CA_KEY"
  value        = data.terraform_remote_state.cloudlab.outputs.loki_ca_key
}

resource "infisical_secret" "loki_client_cert" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.loki.path
  name         = "CLIENT_CERT"
  value        = tls_locally_signed_cert.loki_client.cert_pem
}

resource "infisical_secret" "loki_client_key" {
  workspace_id = infisical_project.homelab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.loki.path
  name         = "CLIENT_KEY"
  value        = tls_private_key.loki_client.private_key_pem
}
