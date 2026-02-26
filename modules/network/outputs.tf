# Network Module Outputs

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}
<<<<<<< HEAD
output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
=======
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)

