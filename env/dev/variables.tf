variable "env" {
  type        = string
  description = "Environment name (e.g. dev, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH into monitoring instance"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "monitoring_instance_type" {
  type        = string
  description = "Monitoring EC2 instance type"
  default     = "t3.micro"
}

variable "service_instance_type" {
  type        = string
  description = "Service EC2 instance type (ASG)"
  default     = "t3.micro"
}

variable "nat_instance_type" {
  type        = string
  description = "NAT instance type"
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  type        = number
  description = "ASG desired capacity"
  default     = 1
}

variable "asg_min_size" {
  type        = number
  description = "ASG min size"
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "ASG max size"
  default     = 2
}

# GitHub Runner / SSM
variable "github_org" {
  type        = string
  description = "GitHub organization name"
}

variable "ssm_pat_param_name" {
  type        = string
  description = "SSM Parameter name (SecureString) for GitHub PAT (include leading slash if used)"
}

variable "ssm_kms_key_arn" {
  type        = string
  description = "Optional KMS key ARN used to encrypt the PAT parameter"
  default     = ""
}

variable "runner_labels" {
  type        = string
  description = "Runner labels"
  default     = "monitoring,linux,x64"
}
