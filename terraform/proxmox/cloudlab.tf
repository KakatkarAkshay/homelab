data "terraform_remote_state" "cloudlab" {
  backend = "oci"

  config = {
    bucket       = var.cloudlab_state_bucket
    namespace    = var.cloudlab_state_namespace
    key          = var.cloudlab_state_key
    region       = var.cloudlab_state_region
    tenancy_ocid = var.tenancy_1_ocid
    user_ocid    = var.tenancy_1_user_ocid
    fingerprint  = var.oci_fingerprint
    private_key  = var.oci_private_key
  }
}
