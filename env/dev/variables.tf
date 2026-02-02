variable "project_name" { type = string }

variable "vpc_cidr" { type = string }

variable "public_subnet_cidrs" { type = list(string) }

variable "private_subnet_cidrs" { type = list(string) }

variable "allowed_ssh_cidrs" { type = list(string) }

variable "key_name" { type = string }

variable "monitoring_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "service_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "nat_instance_type" {
  type    = string
  default = "t3.micro"
}

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

############################################
# Runner vars (monitoring module)
############################################

variable "github_org" {
  type    = string
  default = "ktcloudmini"
}

variable "ssm_pat_param_name" {
  type    = string
  default = "/cicd/github/pat"
}

variable "ssm_kms_key_arn" {
  type    = string
  default = ""
}

variable "runner_labels" {
  type    = string
  default = "monitoring,linux,x64"
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

