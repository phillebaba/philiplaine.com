module "certificate" {
  source = "./modules/acm-certificate"

  providers = {
    "aws.acm" = "aws.us-east-1"
    "aws.route53" = "aws"
  }

  parent_zone_name = "${var.domain}"
  domain_name = "${var.domain}"
  alternative_names = ["www.${var.domain}"]
}

module "static_bucket" {
  source = "./modules/static-bucket-cdn"
  domain_name = "www.${var.domain}"
  index_document = "index.html"
  error_document = "404.html"
  certificate_arn = "${module.certificate.certificate_arn}"
}

data "aws_route53_zone" "default" {
  name    = "${var.domain}"
}

resource "aws_route53_record" "www_route53_record" {
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  name = "www.${var.domain}"
  type = "A"

  alias {
    name = "${module.static_bucket.cdn_domain_name}"
    zone_id = "${module.static_bucket.cdn_hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "route53_record" {
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  name = "${var.domain}"
  type = "A"

  alias {
		name = "www.${var.domain}"
    zone_id = "${data.aws_route53_zone.default.zone_id}"
    evaluate_target_health = false
  }
}

