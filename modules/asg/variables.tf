variable "name" {
  type        = string
  description = "ASG name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for ASG"
}

variable "target_group_arns" {
  type        = list(string)
  description = "Target group ARNs to attach"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "service_sg_id" {
  type        = string
  description = "Security group ID for service instances"
}

variable "desired_capacity" {
  type        = number
  description = "Desired capacity"
}

variable "min_size" {
  type        = number
  description = "Minimum size"
}

variable "max_size" {
  type        = number
  description = "Maximum size"
}

variable "user_data" {
  type        = string
  description = "Optional user_data script"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Extra tags"
  default     = {}
}
