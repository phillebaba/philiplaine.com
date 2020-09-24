terraform {
  backend "s3" {
    bucket     = "terraform-remote-state-1553720878"
    key        = "philiplaine.com/terraform.tfstate"
    region     = "eu-west-1"
    encrypt    = true
    kms_key_id = "626fcaf4-e198-49ab-85e1-e74ffa5f4dbe"
  }
}

