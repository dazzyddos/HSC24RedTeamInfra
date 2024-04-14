output "plaininstance-private-ip" {
  value = concat(aws_instance.plain-host.*.private_ip)
}

output "plaininstance-public-ip" {
  value = concat(aws_instance.plain-host.*.public_ip)
}