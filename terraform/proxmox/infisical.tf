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
