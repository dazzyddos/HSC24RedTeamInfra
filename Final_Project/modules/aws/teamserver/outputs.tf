output "teamserver_private_ip" {
    value = aws_instance.teamserver.private_ip
}

output "teamserver_instance_id" {
  value = aws_instance.teamserver != null ? aws_instance.teamserver.id : null
  description = "The ID of the teamserver instance"
}
