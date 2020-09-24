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
                    [ "AWS/S3", "NumberOfObjects", "StorageType", "AllStorageTypes", "BucketName", "${aws_s3_bucket.default.id}", { "period": 86400 } ],
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
                    [ "AWS/CloudFront", "Requests", "Region", "Global", "DistributionId", "${aws_cloudfront_distribution.default.id}" ]
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
                    [ "AWS/CloudFront", "4xxErrorRate", "Region", "Global", "DistributionId", "${aws_cloudfront_distribution.default.id}" ],
                    [ ".", "5xxErrorRate", ".", ".", ".", "." ]
                ],
                "region": "us-east-1"
            }
        }
    ]
  }
EOF

}
