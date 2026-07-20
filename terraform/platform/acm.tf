# ============================================================
# ACM Certificate — api.neuralops.adinath.site
# DNS validation via Cloudflare (not Route53) — validation
# CNAME must be added manually in Cloudflare once zone is Active.
# ============================================================

resource "aws_acm_certificate" "api_neuralops" {
  domain_name       = "api.neuralops.adinath.site"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-api-neuralops-cert"
  }
}

output "acm_validation_records" {
  description = "Add these as CNAME records in Cloudflare to validate the cert"
  value = {
    for dvo in aws_acm_certificate.api_neuralops.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.api_neuralops.arn
}

# ============================================================
# ACM Certificate — *.neuralops.adinath.site (wildcard)
# Covers grafana, argocd, prometheus, and any future subdomains
# under this pattern. DNS validation via Cloudflare (manual CNAME).
# ============================================================
resource "aws_acm_certificate" "wildcard_neuralops" {
  domain_name       = "*.neuralops.adinath.site"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-wildcard-neuralops-cert"
  }
}

output "wildcard_acm_validation_records" {
  description = "Add these as CNAME records in Cloudflare to validate the wildcard cert"
  value = {
    for dvo in aws_acm_certificate.wildcard_neuralops.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "wildcard_acm_certificate_arn" {
  value = aws_acm_certificate.wildcard_neuralops.arn
}
