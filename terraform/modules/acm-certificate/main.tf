resource "aws_acm_certificate" "default" {
	provider = "aws.acm"
  domain_name = "${var.domain_name}"
  subject_alternative_names = "${var.alternative_names}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "default" {
	provider = "aws.acm"
  certificate_arn = "${aws_acm_certificate.default.arn}"
}

data "aws_route53_zone" "default" {
  provider = "aws.route53"
  name    = "${var.parent_zone_name}"
}

resource "aws_route53_record" "default" {
  provider = "aws.route53"
  count = "${length(aws_acm_certificate.default.domain_validation_options)}"
  name = "${lookup( aws_acm_certificate.default.domain_validation_options[count.index], "resource_record_name")}"
  type = "${lookup( aws_acm_certificate.default.domain_validation_options[count.index], "resource_record_type")}"
  records = ["${lookup( aws_acm_certificate.default.domain_validation_options[count.index], "resource_record_value") }"]
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  ttl = 60
}
