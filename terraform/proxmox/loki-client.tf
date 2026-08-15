resource "tls_private_key" "loki_client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "loki_client" {
  private_key_pem = tls_private_key.loki_client.private_key_pem

  subject {
    common_name  = "homelab-alloy"
    organization = "kakatkarakshay"
  }
}

resource "tls_locally_signed_cert" "loki_client" {
  cert_request_pem   = tls_cert_request.loki_client.cert_request_pem
  ca_private_key_pem = data.terraform_remote_state.cloudlab.outputs.loki_ca_key
  ca_cert_pem        = data.terraform_remote_state.cloudlab.outputs.loki_ca_cert

  validity_period_hours = 8760
  early_renewal_hours   = 720

  allowed_uses = [
    "client_auth",
    "digital_signature",
  ]
}
