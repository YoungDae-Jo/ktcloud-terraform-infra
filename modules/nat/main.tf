resource "aws_security_group" "nat_sg" {
  name        = "${var.project_name}-nat-sg"
  description = "NAT Instance SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "Private subnets to NAT (all)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_subnet_cidrs
  }


  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-nat-sg" })
}

resource "aws_instance" "nat" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  key_name               = var.key_name

  source_dest_check = false
  user_data         = file("${path.module}/user_data.sh")

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat"
    Role = "nat"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

resource "aws_route" "private_default_to_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id

}

