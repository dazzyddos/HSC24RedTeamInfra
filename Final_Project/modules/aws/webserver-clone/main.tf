resource "aws_instance" "websiteclone-host" {

    count                       = var.mycount
    ami                         = var.ami_id
    instance_type               = var.instance_type
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [aws_security_group.websiteclone-sg.id]
    availability_zone           = var.avl_zone
    associate_public_ip_address = true
    key_name                    = var.key_name

    #only allowing ssh through bastion
    connection {
        type = "ssh"
        host = self.private_ip
        bastion_host = var.bastionhostpublicip
        user = var.ssh_user
        private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo hostname ${var.hostname}"
        ]
    }

    provisioner "local-exec" {
        when    = create
        command = "./create_ssh_config.sh '${var.hostname}' '${self.private_ip}' '${var.ssh_user}' './generated_key.pem' './ssh_config' 'false'"
    }

    tags = {
        Name = "${var.hostname}"
    }
}

module "create_A_route53_record" {

    source = "../../../modules/aws/create-dns-record"  
    count = length(var.domain_names)
  
    domain = "${var.domain_names[count.index]}"
    type = "A"
    records = {
        "${var.domain_names[count.index]}" = [aws_instance.websiteclone-host[count.index].public_ip]
    }
}

resource "null_resource" "run_ansbile_websiteclone" {

  depends_on = [ aws_instance.websiteclone-host ]

  count = var.mycount

  connection {
    type        = "ssh"
    host        = var.bastionhostpublicip
    user        = var.ssh_user
    private_key = var.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -- sh -c 'echo ${var.hostname} ${aws_instance.websiteclone-host[count.index].private_ip} >> /etc/hosts'",
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook /home/ubuntu/ansible-playbooks/website-cloner/main.yml -i ${aws_instance.websiteclone-host[count.index].private_ip}, -e 'website_url=${var.website_url[count.index]}'"
    ]
  }
}

resource "null_resource" "run_ansbile_sslsetup" {

  depends_on = [ aws_instance.websiteclone-host , null_resource.run_ansbile_websiteclone]

  count = var.mycount

  connection {
    type        = "ssh"
    host        = var.bastionhostpublicip
    user        = var.ssh_user
    private_key = var.private_key
  }

  provisioner "file" {
    source = "./modules/aws/webserver-clone/server-ssl.conf"
    destination = "/tmp/server-ssl.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook /home/ubuntu/ansible-playbooks/website-cloner/ssl-setup.yml -i ${aws_instance.websiteclone-host[count.index].private_ip}, -e 'DOMAIN=${var.domain_names[count.index]}'"
    ]
  }
}