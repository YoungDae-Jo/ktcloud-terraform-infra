# Network module variables
variable "project_name" {
  type    = string
  default = "ktcloud-infra"
}

variable "vpc_cidr" {
<<<<<<< HEAD
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
=======
  type    = string
}

variable "public_subnet_cidrs" {
  type    = list(string)
}

variable "private_subnet_cidrs" {
  type    = list(string)
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
}

