output redelk-server {
  value = aws_instance.RedELK
}

output "redelk-private-ip" {
  value = aws_instance.RedELK.private_ip
}