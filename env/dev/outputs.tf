############################################
# VPC
############################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

############################################
# Subnets
############################################

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.network.private_subnet_ids
}

############################################
# ALB
############################################

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = module.alb.alb_dns_name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.alb.target_group_arn
}

############################################
# ASG
############################################

output "asg_name" {
  description = "Auto Scaling Group Name"
  value       = module.asg.asg_name
}

############################################
# Monitoring
############################################

output "monitoring_public_ip" {
  description = "Monitoring EC2 Public IP"
  value       = module.monitoring.public_ip
}

