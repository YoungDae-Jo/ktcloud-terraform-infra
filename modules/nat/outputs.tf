output "nat_instance_id" {
  value = aws_instance.nat.id
}

output "nat_private_ip" {
  value = aws_instance.nat.private_ip
}

output "nat_public_ip" {
  value = aws_eip.nat.public_ip
}

output "nat_sg_id" {
  value = aws_security_group.nat_sg.id
}

