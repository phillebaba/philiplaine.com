data "aws_route53_zone" "www" {
  name         = "${var.domain}"
  private_zone = "false"
}
