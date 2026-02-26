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

data "aws_iam_role" "read_tags_for_ansible" {
  name = "ReadTagsForAnsible"
}

data "aws_iam_instance_profile" "read_tags_for_ansible" {
  name = "ReadTagsForAnsible"
}

data "aws_iam_policy_document" "runner_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter${var.ssm_pat_param_name}"
    ]
  }

  dynamic "statement" {
    for_each = (try(var.ssm_kms_key_arn, "") != "") ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]
      resources = [var.ssm_kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "read_pat_from_ssm" {
  name   = "ReadPATFromSSM"
  role   = data.aws_iam_role.read_tags_for_ansible.id
  policy = data.aws_iam_policy_document.runner_ssm_policy.json
}

data "aws_iam_policy_document" "monitoring_ec2_sd_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "monitoring_ec2_sd" {
  name   = "MonitoringEC2ServiceDiscovery"
  role   = data.aws_iam_role.read_tags_for_ansible.id
  policy = data.aws_iam_policy_document.monitoring_ec2_sd_policy.json
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg-monitoring"
  description = "Monitoring/Runner SG (Grafana/Prometheus/SSH)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-monitoring"
  }
}

locals {
  user_data = templatefile("${path.module}/userdata_runner.sh.tpl", {
    ORG            = var.github_org
    SSM_PARAM_NAME = var.ssm_pat_param_name
    RUNNER_LABELS  = var.runner_labels
  })
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  key_name  = var.key_name
  user_data = local.user_data

  iam_instance_profile = data.aws_iam_instance_profile.read_tags_for_ansible.name

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
