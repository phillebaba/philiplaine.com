locals {
  index_document = "index.html"
  error_document = "error.html"
}

resource "aws_s3_bucket" "www" {
  bucket = "${var.domain}"
  acl    = "private"

  website {
    index_document = "${local.index_document}"
    error_document = "${local.error_document}"
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${data.aws_route53_zone.www.zone_id}"
  name = "${var.domain}"
  type = "A"

  alias {
		name = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id = "${aws_cloudfront_distribution.cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.www.zone_id}"
  name = "www.${var.domain}"
  type = "A"

  alias {
		name = "${aws_cloudfront_distribution.cdn.domain_name}"
    zone_id = "${aws_cloudfront_distribution.cdn.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cert_validation" {
  name = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.www.zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

# ACM
resource "aws_acm_certificate" "cert" {
	provider = "aws.us-east-1"
  domain_name = "${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
	provider = "aws.us-east-1"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}

# Cloud Front
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = "${aws_s3_bucket.www.website_endpoint}"
    origin_id   = "origin-${var.domain}"

    # Secret sauce required for the aws api to accept cdn pointing to s3 website endpoint
    # http://stackoverflow.com/questions/40095803/how-do-you-create-an-aws-cloudfront-distribution-that-points-to-an-s3-static-ho#40096056
    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port = "80"
      https_port = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
  default_root_object = "${local.index_document}"
  aliases = ["${var.domain}", "www.${var.domain}"]
  price_class = "PriceClass_100"

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "300"
    response_code         = "404"
    response_page_path    = "/${local.error_document}"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "origin-${var.domain}"

    min_ttl = 0
    default_ttl = 300
    max_ttl = 1200

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

