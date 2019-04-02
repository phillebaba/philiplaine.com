locals {
  tags = {
    Project = "philiplaine.com"
    Environment = "prod"
  }
}

module "s3_static_website" {
  source = "github.com/phillebaba/terraform-modules/modules/s3-static-website"

  tags = "${local.tags}"
  domain_name = "${var.domain_name}"
  index_document = "index.html"
  error_document = "404.html"
  routing_rules = <<EOF
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

  tags = "${local.tags}"
  domain_name = "${var.domain_name}"
  origin_domain_name = "${module.s3_static_website.website_endpoint}"
}
