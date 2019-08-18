locals {
  tags = {
    Project     = "philiplaine.com"
    Environment = "prod"
  }
}

module "s3_static_website" {
  source = "github.com/phillebaba/terraform-modules/modules/s3-static-website"

  tags           = local.tags
  domain_name    = var.domain_name
  index_document = "index.html"
  error_document = "404.html"
  routing_rules  = <<EOF
  [{
    "Redirect": {
      "ReplaceKeyPrefixWith": "index.html"
    },
    "Condition": {
      "KeyPrefixEquals": "/"
    }
  }]
  
EOF

}

module "cloudfront_cdn" {
  source = "github.com/phillebaba/terraform-modules/modules/cloudfront-cdn"

  tags               = local.tags
  domain_name        = var.domain_name
  origin_domain_name = module.s3_static_website.website_endpoint
}

resource "aws_cloudwatch_dashboard" "default" {
  dashboard_name = "philiplaine-com"

  dashboard_body = <<EOF
  {
  "start": "-P7D",
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/S3", "NumberOfObjects", "StorageType", "AllStorageTypes", "BucketName", "${module.s3_static_website.bucket_name}", { "period": 86400 } ],
                    [ ".", "BucketSizeBytes", ".", "StandardStorage", ".", ".", { "period": 86400 } ]
                ],
                "region": "eu-west-1",
                "period": 300,
                "title": "S3 Bucket Storage"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 9,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/CloudFront", "Requests", "Region", "Global", "DistributionId", "${module.cloudfront_cdn.distribution_id}" ]
                ],
                "region": "us-east-1",
                "title": "Total Requests",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 9,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/CloudFront", "4xxErrorRate", "Region", "Global", "DistributionId", "${module.cloudfront_cdn.distribution_id}" ],
                    [ ".", "5xxErrorRate", ".", ".", ".", "." ]
                ],
                "region": "us-east-1"
            }
        }
    ]
  }
EOF

}

