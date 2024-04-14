output "evilginx-host" {
  value = aws_instance.evilginx-host
}

output "evilginx-private-ip" {
  value = aws_instance.evilginx-host.private_ip
}

output "evilginx-public-ip" {
  value = aws_instance.evilginx-host.public_ip
}

output "evilginx_instance_id" {
  value = aws_instance.evilginx-host != null ? aws_instance.evilginx-host.id : null
  description = "The ID of the evilginx instance"
}