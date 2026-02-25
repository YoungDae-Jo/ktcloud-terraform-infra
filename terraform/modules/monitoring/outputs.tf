output "instance_id" {
  value = aws_instance.monitoring.id
}

output "public_ip" {
  value = aws_instance.monitoring.public_ip
}
output "monitoring_instance_id" {
  value = aws_instance.monitoring.id
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "monitoring_public_dns" {
  value = aws_instance.monitoring.public_dns
}

output "monitoring_sg_id" {
  value = aws_security_group.monitoring.id
}


