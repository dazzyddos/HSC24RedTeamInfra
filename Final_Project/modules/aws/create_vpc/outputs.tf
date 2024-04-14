// this just exports the whole object
output create-vpc {
  value = aws_vpc.myvpc
}

// this exports a single value ( which i found to be easy to access )
output "vpc_id" {
  value = aws_vpc.myvpc.id
}

output "subnet1_id" {
  value = aws_subnet.subnet1.id
}

output "subnet2_id" {
    value = aws_subnet.subnet2.id
}

