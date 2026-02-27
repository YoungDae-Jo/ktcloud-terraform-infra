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
# ALB SG
############################################
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "ALB SG"
  vpc_id      = module.network.vpc_id

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

  tags = { Name = "${var.project_name}-sg-alb" }
}

############################################
# Monitoring EC2 (Bastion / Runner / Ansible)
############################################
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.public_subnet_ids[0]

  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  instance_type     = var.monitoring_instance_type
  key_name          = var.key_name

  github_org         = var.github_org
  ssm_pat_param_name = var.ssm_pat_param_name
  ssm_kms_key_arn    = var.ssm_kms_key_arn
  runner_labels      = var.runner_labels
}

############################################
# Service SG (ASG instances)
############################################
resource "aws_security_group" "service" {
  name        = "${var.project_name}-sg-service"
  description = "Service SG (ASG instances)"
  vpc_id      = module.network.vpc_id

  # App traffic from ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # (Optional) app access from monitoring
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [module.monitoring.monitoring_sg_id]
  }

  # Node exporter from monitoring
  ingress {
    description     = "Node Exporter from Monitoring"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [module.monitoring.monitoring_sg_id]
  }

  # SSH from monitoring (bastion)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.monitoring.monitoring_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-service" }
}

############################################
# ALB
############################################
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = aws_security_group.alb.id
}

############################################
# NAT Instance
############################################
module "nat" {
  source = "../../modules/nat"

  project_name           = var.project_name
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = var.vpc_cidr
  public_subnet_id       = module.network.public_subnet_ids[0]
  private_route_table_id = module.network.private_route_table_id
  private_subnet_cidrs   = var.private_subnet_cidrs

  ami_id        = data.aws_ami.ubuntu_2204.id
  instance_type = var.nat_instance_type
  key_name      = var.key_name

  bastion_sg_id = module.monitoring.monitoring_sg_id

  tags = {
    Name = "${var.project_name}-nat"
    Role = "nat"
  }
}

############################################
# ASG (Service)
############################################
module "asg" {
  source = "../../modules/asg"

  name               = "${var.project_name}-service"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  target_group_arns = [module.alb.target_group_arn]

  ami_id        = data.aws_ami.ubuntu_2204.id
  instance_type = var.service_instance_type
  key_name      = var.key_name

  service_sg_id = aws_security_group.service.id

  desired_capacity = var.asg_desired_capacity
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
}
