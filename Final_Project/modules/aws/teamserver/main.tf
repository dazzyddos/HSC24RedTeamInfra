resource "aws_instance" "teamserver" {
    ami = var.ami_id
    instance_type = "t2.micro"
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.teamserver-sg.id]
    availability_zone = var.avl_zone
    key_name = var.key_name

    tags = {
        Name = "teamserver"
    }

    connection {
          type = "ssh"
          user = "ubuntu"
          host = self.private_ip
          bastion_host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo hostnamectl set-hostname teamserver"
        ]
    }
}

resource "null_resource" "run_ansible_playbook" {
    depends_on = [aws_instance.teamserver]

    count = var.install_redelk ? 1 : 0

    connection {
          type = "ssh"
          user = var.ssh_user
          host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo -- sh -c 'echo ${aws_instance.teamserver.private_ip} teamserver >> /etc/hosts'"
        ]
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("./Ansible-Playbooks/teamserver/inventory.tpl", { teamserver_private_ip = aws_instance.teamserver.private_ip })
        destination = "/home/ubuntu/ansible-playbooks/teamserver/inventory.ini"
    }

    provisioner "remote-exec" {
        inline = [
            "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/teamserver/inventory.ini /home/ubuntu/ansible-playbooks/teamserver/teamserver.yml"
        ]
    }
}
