variable "project_name" { type = string }
variable "vpc_id" { type = string }

variable "public_subnet_id" { type = string }
variable "private_route_table_id" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs allowed to use NAT"
}

variable "ami_id" { type = string }

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" { type = string }

variable "bastion_sg_id" {
  type        = string
  description = "Monitoring(Bastion) Security Group ID"
}

variable "tags" {
  type    = map(string)
  default = {}
}

