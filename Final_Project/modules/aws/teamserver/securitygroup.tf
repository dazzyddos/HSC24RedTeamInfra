// security group for the Havoc C2, we are opening port 22 only for the bastion host
resource "aws_security_group" "teamserver-sg" {
    name = "teamserver-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.bastionhostprivateip}/32"]
    }

    ingress {
        from_port   = 40056
        to_port     = 40056
        protocol    = "tcp"
        cidr_blocks = ["${var.bastionhostprivateip}/32"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }

    ingress {
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = ["10.0.1.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "teamserver-sg"
    }
}