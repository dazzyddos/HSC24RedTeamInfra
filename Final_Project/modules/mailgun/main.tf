terraform {
  required_providers {
    mailgun = {
      source = "wgebis/mailgun"
      version = "0.7.4"
    }
  }
}

provider "mailgun" {
  api_key = "<mailgun API Key>"
}

module "namecheap_to_route53" {
  source = "../../modules/aws/namecheap-to-route53"

  domains = var.mailgun_domain_name
}

# Create a new Mailgun domain
resource "mailgun_domain" "default" {
  depends_on = [
    module.namecheap_to_route53
  ]

  count         = length(var.mailgun_domain_name)
  name          = "${var.mailgun_domain_name[count.index]}"
  region        = var.mailgun_region
  spam_action   = "disabled"
  dkim_key_size   = 1024
}

data "mailgun_domain" "domain" {
 count = length(var.mailgun_domain_name) 
    depends_on = [
      mailgun_domain.default
    ]
  name = var.mailgun_domain_name[count.index]
}

# Create a new SMTP Mailgun credential
resource "mailgun_domain_credential" "mail_smtp_creds" {
    depends_on = [
      mailgun_domain.default
    ]

    count = length(var.mailgun_domain_name)
    domain = var.mailgun_domain_name[count.index]
    login = var.mailgun_smtp_users[count.index]
    password = var.mailgun_smtp_passwords[count.index]
    region = "us"

    lifecycle {
        ignore_changes = [password]
    }
}

data "aws_route53_zone" "selected" {
 count = length(var.mailgun_domain_name)     
    depends_on = [
      mailgun_domain.default, module.namecheap_to_route53
    ]
  name  = var.mailgun_domain_name[count.index]
}

# not needed anymore as we will be pointing MX record to the smtp redirector host
# resource "aws_route53_record" "mailgun-mx" {
#   count = length(var.mailgun_domain_name)     
#   depends_on = [
#       mailgun_domain.default, module.namecheap_to_route53
#   ]
#   zone_id = data.aws_route53_zone.selected[count.index].zone_id
#   name    = data.mailgun_domain.domain[count.index].name
#   type    = "MX"
#   ttl     = 60
#   records = [
#         "${data.mailgun_domain.domain[count.index].receiving_records.0.priority} mail.${var.mailgun_domain_name[count.index]}.",
#   ]
# }

resource "aws_route53_record" "mailgun-dkim" {
  count = length(var.mailgun_domain_name)     
  depends_on = [
      mailgun_domain.default, module.namecheap_to_route53
  ]
  zone_id = data.aws_route53_zone.selected[count.index].zone_id
  name    = "${data.mailgun_domain.domain[count.index].sending_records.1.name}"
  type    = "TXT"
  ttl     = 60
  records = [
        "${data.mailgun_domain.domain[count.index].sending_records.1.value}"
  ]
}

resource "aws_route53_record" "mailgun-spf" {
  count = length(var.mailgun_domain_name)     
  depends_on = [
      mailgun_domain.default, module.namecheap_to_route53
  ]
  zone_id = data.aws_route53_zone.selected[count.index].zone_id
  name    = "${data.mailgun_domain.domain[count.index].sending_records.0.name}"
  type    = "TXT"
  ttl     = 60
  records = [
        "${data.mailgun_domain.domain[count.index].sending_records.0.value}",
  ]
}

resource "aws_route53_record" "mailgun-cname" {
  count = length(var.mailgun_domain_name)     
  depends_on = [
      mailgun_domain.default, module.namecheap_to_route53
  ]
  zone_id = data.aws_route53_zone.selected[count.index].zone_id
  name    = "email"
  type    = "CNAME"
  ttl     = 5

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "email"
  records = [
        "mailgun.org"
  ]
}

// we need to add an extra dmarc record to get better score from mail-tester (this domain record addition is not related to mailgun activity)
resource "aws_route53_record" "dmarc-record" {
  count = length(var.mailgun_domain_name)     
  depends_on = [
      mailgun_domain.default, module.namecheap_to_route53
  ]
  zone_id = data.aws_route53_zone.selected[count.index].zone_id
  name    = "_dmarc"
  type    = "TXT"
  ttl     = 60
  records = [
        "v=DMARC1; p=none"
  ]
}
