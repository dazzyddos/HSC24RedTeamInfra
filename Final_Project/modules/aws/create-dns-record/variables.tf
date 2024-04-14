variable "domain" {}

variable "type" {}

variable "hosts" {
  default = 1
}

variable "ttl" {
  default = 120
}

variable "records" {
  type = map(any)
}
