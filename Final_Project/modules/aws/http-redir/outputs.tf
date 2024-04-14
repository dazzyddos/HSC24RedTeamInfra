output "httpredir-host" {
  value = aws_instance.httpredir-host
}

output "httpredir-private-ip" {
  value = concat(aws_instance.httpredir-host.*.private_ip)
}

output "httpredir-public-ip" {
  value = concat(aws_instance.httpredir-host.*.public_ip)
}