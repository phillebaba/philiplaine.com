locals {
  index_document = "index.html"
  error_document = "404.html"
  domains        = ["${var.domain}", "www.${var.domain}"]
}

# S3
resource "aws_s3_bucket" "www" {
  bucket = "${var.domain}"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["philiplaine.com", "www.philiplaine.com", "https://philiplaine.com", "https://www.philiplaine.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  website {
    index_document = "${local.index_document}"
    error_document = "${local.error_document}"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.www.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "origin_policy" {
  bucket = "${aws_s3_bucket.www.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}


# Cloud Front
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.domain}"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "${local.index_document}"
  price_class = "PriceClass_100"

  origin {
    domain_name = "${aws_s3_bucket.www.bucket_regional_domain_name}"
    origin_id   = "origin-${var.domain}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  aliases = ["${var.domain}", "www.${var.domain}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-${var.domain}"

    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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


# Route 53
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
