data "aws_route53_zone" "default" {
  name = var.domain_name
}

resource "aws_route53_record" "www_root" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.default.domain_name
    zone_id                = aws_cloudfront_distribution.default.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_route53_record.www_root.name
    zone_id                = data.aws_route53_zone.default.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.default.zone_id
}
