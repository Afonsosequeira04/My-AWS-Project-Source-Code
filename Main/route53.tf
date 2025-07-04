variable "route53_zone_id" {
  type    = string
  default = "Z01080082M7TFPROC4YKQ"
}

variable "acm_certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:097648937889:certificate/7bbee294-827d-4f45-aadc-754e41247fe4"
}

# A record (alias) for root domain: checkthattask.xyz
resource "aws_route53_record" "root_alias" {
  zone_id = var.route53_zone_id
  name    = "checkthattask.xyz"
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}

# CNAME or alias for www subdomain: www.checkthattask.xyz
resource "aws_route53_record" "www_cname" {
  zone_id = var.route53_zone_id
  name    = "www.checkthattask.xyz"
  type    = "CNAME"
  ttl     = 300
  records = [module.alb.lb_dns_name]
}
