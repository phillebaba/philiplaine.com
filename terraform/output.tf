output "s3_bucket_name" {
  value = aws_s3_bucket.default.id
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.default.id
}
