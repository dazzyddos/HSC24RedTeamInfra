// security group for the plain host, we are opening 22,80,443 to internet
resource "aws_security_group" "plain-sg" {
    name = "${var.hostname}-sg"
    vpc_id = var.vpc_id

    dynamic "ingress" {
      for_each = var.open_ports

      content {
        from_port   = ingress.value
        to_port     = ingress.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }

    ingress {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["${var.bastionhostprivateip}/32"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
