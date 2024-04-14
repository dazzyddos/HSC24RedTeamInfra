resource "aws_instance" "RedELK" {
    ami = var.ami_id
    instance_type = "t3.xlarge"
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.redelk-sg.id]
    availability_zone = var.avl_zone
    key_name = var.key_name
    private_ip = "10.0.2.103"

    tags = {
        Name = "RedELK_Server"
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
            "sudo hostnamectl set-hostname redelk"
        ]
    }

    provisioner "local-exec" {
        when    = create
        command = "./create_ssh_config.sh 'redelk' '${self.private_ip}' '${var.ssh_user}' './generated_key.pem' './ssh_config' 'false'"
    }
}

# run elkservers.tgz on the redelk instance
resource "null_resource" "ansible_run_elkserver" {

    depends_on = [ aws_instance.RedELK ]

    triggers = {
        always_run = timestamp()
    }

    connection {
        type        = "ssh"
        host        = var.bastionhostpublicip
        user        = var.ssh_user
        private_key = var.private_key
    }

    provisioner "file" {
        source      = "./Ansible-Playbooks/redelk/setup_redelk.yml"
        destination = "/home/ubuntu/ansible-playbooks/redelk/setup_redelk.yml"
    }

    # Dynamically create and transfer inventory file
    provisioner "file" {
        content     = templatefile("./Ansible-Playbooks/redelk/inventory.tpl", { redelk_private_ip = aws_instance.RedELK.private_ip })
        destination = "/home/ubuntu/ansible-playbooks/redelk/inventory.ini"
    }

    provisioner "remote-exec" {
      inline = [
        "Installing 'RedELK Server...'",
        "sudo -- sh -c 'echo ${aws_instance.RedELK.private_ip} redelk >> /etc/hosts'",
        "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /home/ubuntu/ansible-playbooks/redelk/inventory.ini /home/ubuntu/ansible-playbooks/redelk/setup_redelk.yml --extra-vars 'C2IP=${var.teamserver_private_ip} C2HOST=${var.teamserver_hostname}'",
      ]
    }
}