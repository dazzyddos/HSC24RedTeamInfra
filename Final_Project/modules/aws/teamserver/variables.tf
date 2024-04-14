variable "vpc_id" {}

variable "subnet_id" {}

variable "avl_zone" {}

variable "key_name" {}

variable "private_key" {}

variable "ssh_user" {}

variable "ami_id" {}

variable "bastionhostprivateip" {}

variable "bastionhostpublicip" {}

variable "install_redelk" {
    type = bool
}