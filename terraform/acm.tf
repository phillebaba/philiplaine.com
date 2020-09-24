resource "aws_acm_certificate" "default" {
  provider                  = aws.us_east_1
  domain_name               = local.aliases[0]
  subject_alternative_names = [local.aliases[1]]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}

resource "aws_acm_certificate_validation" "default" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
