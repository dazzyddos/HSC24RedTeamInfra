resource "aws_instance" "httpredir-host" {
    count                       = var.mycount
    ami                         = var.ami_id
    instance_type               = "t2.micro"
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [aws_security_group.httpredir-sg.id]
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
            "sudo hostnamectl set-hostname httpredir${count.index+1}"
        ]
    }

    provisioner "local-exec" {
        when    = create
        command = "./create_ssh_config.sh 'httpredir${count.index+1}' '${self.private_ip}' '${var.ssh_user}' './generated_key.pem' './ssh_config' 'false'"
    }

    tags = {
      Name = "httpredir-host${count.index+1}"
    }
}

locals {
    httpredir_host_ips = aws_instance.httpredir-host.*.private_ip
}

resource "null_resource" "run_ansible_playbook" {
    depends_on = [aws_instance.httpredir-host]

    count = length(aws_instance.httpredir-host.*.private_ip)

    connection {
          type = "ssh"
          user = var.ssh_user
          host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo -- sh -c 'echo ${aws_instance.httpredir-host[count.index].private_ip} httpredir${count.index+1} >> /etc/hosts'"
        ]
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("./Ansible-Playbooks/http-redir/inventory.tpl", { httpredir_private_ip = local.httpredir_host_ips })
        destination = "/home/ubuntu/ansible-playbooks/http-redir/inventory.ini"
    }

    provisioner "file" {
        source      = "./modules/aws/http-redir/redelk_httpredir.conf"
        destination = "/tmp/redelk_httpredir.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/http-redir/inventory.ini /home/ubuntu/ansible-playbooks/http-redir/http_redirector_setup.yml --extra-vars 'C2IP=${var.cs_private_ip} PUBIP=${aws_instance.httpredir-host[count.index].public_ip} REDIRECT_URL=${var.redirect_url} MY_URI=${var.my_uri} HOSTNAME=httpredir${count.index+1}'"
        ]
    }
}

resource "null_resource" "install_redelk" {
    depends_on = [null_resource.run_ansible_playbook]

    count = var.install_redelk ? length(aws_instance.httpredir-host.*.private_ip) : 0

    connection {
          type = "ssh"
          user = var.ssh_user
          host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
      inline = [
        "Installing 'RedELK redirs...'",
        "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/http-redir/inventory.ini /home/ubuntu/ansible-playbooks/http-redir/setup_redelk.yml --extra-vars 'HOSTNAME=httpredir${count.index+1}'",
      ]
    }
}