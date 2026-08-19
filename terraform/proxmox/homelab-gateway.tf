data "cloudflare_zone" "homelab" {
  filter = {
    name = var.cloudflare_zone
  }
}

resource "cloudflare_dns_record" "homelab_gateway" {
  zone_id = data.cloudflare_zone.homelab.id
  name    = "homelab-gateway.${var.cloudflare_zone}"
  type    = "A"
  content = var.homelab_public_ip
  ttl     = 1
  proxied = true
}
