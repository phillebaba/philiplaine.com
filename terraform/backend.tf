terraform {
  backend "s3" {
    bucket = "terraform-remote-state-1553720878"
    key    = "philiplaine.com/terraform.tfstate"
    region = "eu-west-1"
  }
}

