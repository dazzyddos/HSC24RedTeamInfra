terraform {
  required_version = ">= 1.1.5"
}

data "aws_route53_zone" "selected" {
  name  = var.domain
}

resource "aws_route53_record" "record" {
  allow_overwrite = true
  count = var.hosts
  zone_id = data.aws_route53_zone.selected.zone_id
  name = element(keys(var.records), count.index)
  type = var.type
  ttl = var.ttl
  records = lookup(var.records, element(keys(var.records), count.index))
}
