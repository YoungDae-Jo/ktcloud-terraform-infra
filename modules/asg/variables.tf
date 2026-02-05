variable "name" {
  type = string
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = null
}

variable "service_sg_id" {
  type = string
  description = "ASG base name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ASG"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ALB target group ARNs to attach"
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "AMI ID for service instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name (optional if using SSM only)"
  type        = string
  default     = null
}

variable "service_sg_id" {
  description = "Security Group ID for service instances"
  type        = string
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "user_data" {
  type    = string
  default = ""
}

variable "iam_instance_profile_name" {
  type    = string
  default = null
}
  description = "User data script (plain text). Will be base64-encoded."
  type        = string
  default     = ""
}

