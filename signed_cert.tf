# ----------------------------------------------------------------
# Selft signed certs as no domain name required
# ----------------------------------------------------------------
resource "tls_private_key" "icey_key" {
    algorithm = "RSA"
    rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "cert" {
    key_algorithm   = "RSA"
    private_key_pem = tls_private_key.icey_key.private_key_pem

    subject {
      common_name   = "evenex.ak"
      organization  = "Coffee 1024, Inc"
    }

    validity_period_hours = 240
    allowed_uses          = ["digital_signature", "data_encipherment", "server_auth", "client_auth"]
}

resource "aws_acm_certificate" "default" {
    private_key      = tls_private_key.icey_key.private_key_pem
    certificate_body = tls_self_signed_cert.cert.cert_pem
}

# ----------------------------------------------------------------