module "s3_static_website" {
  source = "github.com/phillebaba/terraform-modules/modules/s3-static-website"

  domain_name = "${var.domain_name}"
  index_document = "index.html"
  error_document = "error.html"
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

  domain_name = "${var.domain_name}"
  origin_domain_name = "${module.s3_static_website.s3_website_endpoint}"
}
