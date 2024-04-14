provider "aws" {
  region = "us-east-1" # You can change this to your preferred region
}
# resource that generates a new RSA private key
resource "tls_private_key" "webserver_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This will save the private key to a file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.webserver_key.private_key_pem
  filename = "${path.module}/generated_key.pem" # This will save the key in the current directory as 'generated_key.pem'
}

# esource that uploads the generated public key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "webserver-key"
  public_key = tls_private_key.webserver_key.public_key_openssh
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID for Ubuntu images

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
    ami                    = data.aws_ami.latest_ubuntu.id
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.generated_key.key_name # Reference the generated key name here
    vpc_security_group_ids = [aws_security_group.webserver-sg.id]
    associate_public_ip_address = true


    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = tls_private_key.webserver_key.private_key_pem
        host        = aws_instance.web.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update -y",
            "sudo apt-get install -y apache2",
            "sudo systemctl start apache2"
        ]
    }

    tags = {
        Name = "UbuntuApacheServer"
    }
}


# Output the location of the saved private key file
output "private_key_path" {
  value     = local_file.private_key_pem.filename
  sensitive = false
}
