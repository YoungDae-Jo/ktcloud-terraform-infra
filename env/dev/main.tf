############################################
# AMI
############################################

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################
# Network
############################################

module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

############################################
# Monitoring EC2
############################################

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.public_subnet_ids[0]

  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  instance_type     = var.monitoring_instance_type
  key_name          = var.key_name
}

############################################
# ALB SG
############################################

resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

############################################
# ALB Module
############################################

module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  alb_sg_id = aws_security_group.alb.id
}

############################################
# Service SG
############################################

resource "aws_security_group" "service" {
  name   = "${var.project_name}-service-sg"
  vpc_id = module.network.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-service-sg"
  }
}

############################################
# ASG
############################################

module "asg" {
  source = "../../modules/asg"

  name               = var.project_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  target_group_arns  = [module.alb.target_group_arn]

  ami_id        = data.aws_ami.ubuntu_2204.id
  instance_type = var.service_instance_type
  key_name      = var.key_name
  service_sg_id = aws_security_group.service.id

  desired_capacity = var.asg_desired_capacity
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "ok - $(hostname)" > /var/www/html/index.html
  EOF
}

