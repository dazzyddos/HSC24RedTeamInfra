variable "region" {
  default = "us-east-1"
}

variable "avl_zone" {
  default = "us-east-1a"
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "domains" {
  type    = list(string)
  default = ["newhireintro.com"] # this variable is for transferring from namecheap to AWS route53
}

variable "evilginx_domain_name" {
  default = "newhireintro.com"
}