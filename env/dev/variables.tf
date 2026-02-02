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

variable "allowed_ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR (ex: your_public_ip/32)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for monitoring server"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name (optional). If null, you can't SSH."
  default     = null
}

