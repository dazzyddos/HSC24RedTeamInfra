output "gophish-host" {
  value = aws_instance.gophish-host
}

output "gophish-private-ip" {
  value = aws_instance.gophish-host.private_ip
}

output "gophish_instance_id" {
  value = aws_instance.gophish-host != null ? aws_instance.gophish-host.id : null
  description = "The ID of the gophish instance"
}