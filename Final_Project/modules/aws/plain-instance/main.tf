resource "aws_instance" "plain-host" {

    count                       = var.mycount
    ami                         = var.ami_id
    instance_type               = var.instance_type
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [aws_security_group.plain-sg.id]
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
}

module "create_A_route53_record" {

    source = "../../../modules/aws/create-dns-record"  
    count = length(var.domain_names)
  
    domain = "${var.domain_names[count.index]}"
    type = "A"
    records = {
        "${var.domain_names[count.index]}" = [aws_instance.plain-host[count.index].public_ip]
  }
}

resource "null_resource" "run_ansible" {

  // only create this resource if the ansible_playbook was specified
  count = var.ansible_playbook != "" ? var.mycount : 0

  connection {
    type        = "ssh"
    host        = var.bastionhostpublicip
    user        = var.ssh_user
    private_key = var.private_key
  }

  provisioner "file" {
    source = "${var.ansible_playbook}"
    destination = "/tmp/tmp_playbook.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook /tmp/tmp_playbook.yml -i ${aws_instance.plain-host[var.mycount.index].private_ip}"
    ]
  }
}