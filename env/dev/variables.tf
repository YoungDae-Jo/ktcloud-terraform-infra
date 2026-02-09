############################################
# Environment Variables (dev)
############################################

variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "SSH allowed CIDR"
}

variable "key_name" {
  type    = string
  default = "ktcloud-key"
}

# Monitoring EC2
variable "monitoring_instance_type" {
  type    = string
  default = "t3.micro"
}

# Service (ASG)
variable "service_instance_type" {
  type    = string
  default = "t3.micro"
}

# ASG Capacity
variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 2
}

