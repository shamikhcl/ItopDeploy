output "vpc_id" {
  value = aws_vpc.this.id
}

# placeholder lists - update with real subnet resources when you add them
output "private_subnet_ids" {
  value = []
}

output "public_subnet_ids" {
  value = []
}
