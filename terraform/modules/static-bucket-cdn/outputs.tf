output "cdn_domain_name" {
  value = "${aws_cloudfront_distribution.default.domain_name}"
}

output "cdn_hosted_zone_id" {
  value = "${aws_cloudfront_distribution.default.hosted_zone_id}"
}
