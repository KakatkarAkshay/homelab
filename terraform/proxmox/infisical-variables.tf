variable "infisical_host" {
  description = "Base URL of the Infisical instance."
  type        = string
  default     = "https://eu.infisical.com"
}

variable "infisical_auth_method" {
  description = "Infisical machine identity auth method. Local runs use universal; CI uses oidc."
  type        = string
  default     = "universal"

  validation {
    condition     = contains(["oidc", "universal"], var.infisical_auth_method)
    error_message = "infisical_auth_method must be oidc or universal."
  }
}

variable "infisical_org_id" {
  description = "Infisical organization ID that owns the homelab project."
  type        = string
}

variable "infisical_environment_slug" {
  description = "Infisical environment secrets are read from."
  type        = string
  default     = "prod"
}
