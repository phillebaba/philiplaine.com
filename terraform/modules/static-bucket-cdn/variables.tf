variable "domain_name" {}

variable "aliases" {
  type = "list"
}

variable "index_document" {}

variable "error_document" {}

variable "certificate_arn" {
  type = "string"
}
