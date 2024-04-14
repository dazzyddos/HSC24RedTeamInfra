terraform {
  required_providers {
    namecheap = {
      source = "namecheap/namecheap"
      version = "2.1.0"
    }
  }
}

provider "namecheap" {
  user_name = "dazzyddos"
  api_user  = "dazzyddos"
  api_key   = "<namecheap API KEY>"
}

resource "aws_route53_zone" "zone" {
    for_each = toset(var.domains)
    
    name = each.value
    comment = "moving domains"
    tags = {
        Name = "route53_zone"
    }
}

resource "namecheap_domain_records" "mydns" {
    for_each = aws_route53_zone.zone
    domain = each.value.name
    mode = "OVERWRITE"
    nameservers = each.value.name_servers
}


