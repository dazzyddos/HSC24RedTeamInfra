provider "aws" {
    region = "us-east-1" # You can change this to your preferred region
}
# resource that generates a new RSA private key
resource "tls_private_key" "terra_sshkey" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# This will save the private key to a file
resource "local_file" "private_key_pem" {
    content  = tls_private_key.terra_sshkey.private_key_pem
    filename = "${path.module}/generated_key.pem" # This will save the key in the current directory as 'generated_key.pem'
}

# esource that uploads the generated public key to AWS
resource "aws_key_pair" "generated_key" {
    key_name   = "terra-sshkey"
    public_key = tls_private_key.terra_sshkey.public_key_openssh
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

# EC2 instance for the bastion host
resource "aws_instance" "bastion_host" {
    ami                    = data.aws_ami.latest_ubuntu.id
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.generated_key.key_name
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true
    tags = {
        Name = "BastionHost"
    }

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = tls_private_key.terra_sshkey.private_key_pem
        host        = aws_instance.bastion_host.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update",
            "sudo apt install software-properties-common -y",
            "sudo apt-add-repository --yes --update ppa:ansible/ansible",
            "sudo apt install ansible -y"
        ]
    }
}

# EC2 instance for the webserver host
resource "aws_instance" "web" {
    ami                    = data.aws_ami.latest_ubuntu.id
    instance_type          = "t2.micro"
    key_name               = aws_key_pair.generated_key.key_name # Reference the generated key name here
    vpc_security_group_ids = [aws_security_group.webserver-sg.id]
    associate_public_ip_address = true


    # connection {
    #     type        = "ssh"
    #     user        = "ubuntu"
    #     private_key = tls_private_key.terra_sshkey.private_key_pem
    #     host        = self.private_ip
    #     bastion_host = aws_instance.bastion_host.public_ip
    # }

    # provisioner "remote-exec" {
    #     inline = [
    #         "sudo apt update",
    #         "sudo apt-get install -y apache2",
    #         "sudo systemctl start apache2"
    #     ]
    # }

    tags = {
        Name = "UbuntuApacheServer"
    }
}

resource "null_resource" "run_ansible_playbook" {
    depends_on = [aws_instance.bastion_host, aws_instance.web]

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = tls_private_key.terra_sshkey.private_key_pem
        host        = aws_instance.bastion_host.public_ip
    }

    # Transfer private ssh key
    provisioner "file" {
        source      = "generated_key.pem"
        destination = "/home/ubuntu/deployer-key.pem"
    }

    # Transfer Ansible playbook
    provisioner "file" {
        source      = "../Ansible-Playbooks/setup_webserver.yml"
        destination = "/home/ubuntu/setup_webserver.yml"
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("../Ansible-Playbooks/inventory.tpl", { web_server_private_ip = aws_instance.web.private_ip })
        destination = "/home/ubuntu/inventory.ini"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod 600 /home/ubuntu/deployer-key.pem",
            "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini setup_webserver.yml"
        ]
    }
}


# Output the location of the saved private key file
output "private_key_path" {
    value     = local_file.private_key_pem.filename
    sensitive = false
}

# output the public ip of the web server
output "webserver-public-ip" {
    value = aws_instance.web.public_ip
}

output "bastion-public-ip" {
    value = aws_instance.bastion_host.public_ip
}