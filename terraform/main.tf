terraform {
  required_version = "=0.13.3"
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}

locals {
  tags = {
    Project     = "philiplaine.com"
    Environment = "prod"
  }
  aliases   = ["www.${var.domain_name}", "${var.domain_name}"]
  origin_id = "origin-${var.domain_name}"
}
