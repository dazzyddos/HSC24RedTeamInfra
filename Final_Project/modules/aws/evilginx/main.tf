resource "aws_instance" "evilginx-host" {
    ami                         = var.ami_id
    instance_type               = "t2.micro"
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [aws_security_group.evilginx-sg.id]
    availability_zone           = var.avl_zone
    associate_public_ip_address = true
    key_name                    = var.key_name

    connection {
          type = "ssh"
          user = "${var.ssh_user}"
          host = self.private_ip
          bastion_host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo hostnamectl set-hostname evilginx"
        ]
    }

    provisioner "local-exec" {
        when    = create
        command = "./create_ssh_config.sh 'evilginx' '${self.private_ip}' 'evilginx' './generated_key.pem' './ssh_config' 'false'"
    }

    tags = {
        Name = "evilginx"
    }
}

module "create_A_route53_record" {

    depends_on = [aws_instance.evilginx-host]

    source = "../../../modules/aws/create-dns-record"  
  
    domain = "${var.domain_name}"
    type = "A"
    records = {
        "${var.domain_name}" = [aws_instance.evilginx-host.public_ip]
    }
}

module "create_ns1_route53_record_for_evilginx" {

    depends_on = [aws_instance.evilginx-host]

    source = "../../../modules/aws/create-dns-record"  
    
    domain = "${var.domain_name}"
    type = "NS"
    records = {
        "ns1.${var.domain_name}" = [aws_instance.evilginx-host.public_ip]
    }
}

module "create_ns2_route53_record_for_evilginx" {

    depends_on = [aws_instance.evilginx-host]

    source = "../../../modules/aws/create-dns-record"  
    
    domain = "${var.domain_name}"
    type = "NS"
    records = {
        "ns2.${var.domain_name}" = [aws_instance.evilginx-host.public_ip]
    }
}

resource "null_resource" "run_ansible_playbook" {
    depends_on = [aws_instance.evilginx-host]

    connection {
          type = "ssh"
          user = var.ssh_user
          host = var.bastionhostpublicip
          private_key = var.private_key
    }

    provisioner "remote-exec" {
        inline = [
            "sudo -- sh -c 'echo ${aws_instance.evilginx-host.private_ip} evilginx >> /etc/hosts'"
        ]
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("./Ansible-Playbooks/evilginx/inventory.tpl", { evilginx_private_ip = aws_instance.evilginx-host.private_ip})
        destination = "/home/ubuntu/ansible-playbooks/evilginx/inventory.ini"
    }

    provisioner "remote-exec" {
        inline = [
            "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/evilginx/inventory.ini /home/ubuntu/ansible-playbooks/evilginx/evilginx_setup.yml"
        ]
    }
}