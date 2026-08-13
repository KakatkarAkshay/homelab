variable "cloudlab_state_bucket" {
  description = "OCI Object Storage bucket holding the cloudlab Terraform state."
  type        = string
  default     = "cloudlab-terraform-state"
}

variable "cloudlab_state_namespace" {
  description = "OCI Object Storage namespace holding the cloudlab Terraform state."
  type        = string
  default     = "bms1yohq0tse"
}

variable "cloudlab_state_key" {
  description = "Object key of the cloudlab infra Terraform state."
  type        = string
  default     = "cloudlab/terraform.tfstate"
}

variable "cloudlab_state_region" {
  description = "OCI region of the cloudlab Terraform state bucket."
  type        = string
  default     = "ap-mumbai-1"
}

variable "tenancy_1_ocid" {
  description = "OCID of the tenancy owning the state bucket."
  type        = string
}

variable "tenancy_1_user_ocid" {
  description = "OCID of the user reading the state bucket."
  type        = string
}

variable "oci_fingerprint" {
  description = "Fingerprint of the OCI API key."
  type        = string
}

variable "oci_private_key" {
  description = "OCI API private key in PEM form."
  type        = string
  sensitive   = true
}
