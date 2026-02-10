# Network module variables
variable "project_name" {
  type    = string
  default = "ktcloud-infra"
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

