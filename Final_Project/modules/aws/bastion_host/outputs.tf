output "bastion-ip" {
    value = "Bastion Public IP: ${aws_instance.bastion_host.public_ip}"
}

output "bastion-private-ip" {
    value = aws_instance.bastion_host.private_ip
}

output "bastion-public-ip" {
    value = aws_instance.bastion_host.public_ip
}

# this is for the redelk module in main. Since we want the redelk server to only get pwned when this value is true in bastion module
output "install_redelk" {
  value = var.install_redelk
}
