resource "aws_instance" "gophish-host" {
    #count                       = var.mycount
    ami                         = var.ami_id
    instance_type               = "t2.micro"
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [aws_security_group.gophish-sg.id]
    availability_zone           = var.avl_zone
    associate_public_ip_address = true
    key_name                    = var.key_name

    connection {
          type = "ssh"
          user = "ubuntu"
          host = self.private_ip
          bastion_host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo hostnamectl set-hostname gophish"
        ]
    }

    provisioner "local-exec" {
        when    = create
        command = "./create_ssh_config.sh 'gophish' '${self.private_ip}' '${var.ssh_user}' './generated_key.pem' './ssh_config' 'false'"
    }

    tags = {
      Name = "gophish-host"
    }
}

resource "null_resource" "run_ansible_playbook" {
    depends_on = [aws_instance.gophish-host]

    connection {
          type = "ssh"
          user = var.ssh_user
          host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo -- sh -c 'echo ${aws_instance.gophish-host.private_ip} gophish >> /etc/hosts'"
        ]
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("./Ansible-Playbooks/gophish/inventory.tpl", { gophish_private_ip = aws_instance.gophish-host.private_ip })
        destination = "/home/ubuntu/ansible-playbooks/gophish/inventory.ini"
    }

    provisioner "remote-exec" {
        inline = [
            "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/gophish/inventory.ini /home/ubuntu/ansible-playbooks/gophish/gophish_setup.yml --extra-vars 'PRIVATE_IP=${aws_instance.gophish-host.private_ip}'"
        ]
    }
}