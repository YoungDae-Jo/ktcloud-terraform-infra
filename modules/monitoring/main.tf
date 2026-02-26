<<<<<<< HEAD
############################################
# AMI
############################################

=======
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

<<<<<<< HEAD
############################################
# IAM: reuse existing Role + existing Instance Profile
# - Role: ReadTagsForAnsible (already exists)
# - Instance Profile: ReadTagsForAnsible (already exists)
# Add minimum permissions to read GH PAT from SSM Parameter Store.
############################################

data "aws_iam_role" "read_tags_for_ansible" {
  name = "ReadTagsForAnsible"
}

data "aws_iam_instance_profile" "read_tags_for_ansible" {
  name = "ReadTagsForAnsible"
}

# --- Extra policy: read GH PAT from SSM (SecureString) ---
# 필요 최소 권한: ssm:GetParameter (with-decryption)
# SecureString + CMK 사용 시 kms:Decrypt도 필요할 수 있음 (var.ssm_kms_key_arn에 ARN 넣으면 자동 추가)

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

############################################
# Security Group (Monitoring)
############################################

=======
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg-monitoring"
  description = "Monitoring SG (Grafana/Prometheus/SSH)"
  vpc_id      = var.vpc_id

<<<<<<< HEAD
  # Grafana
  ingress {
    description = "Grafana from Admin CIDRs"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Prometheus
  ingress {
    description = "Prometheus UI/API from Admin CIDRs"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # SSH
=======
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
<<<<<<< HEAD
    cidr_blocks = var.allowed_ssh_cidrs
=======
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # (선택) Node Exporter용 - 필요하면 사용
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
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

<<<<<<< HEAD
############################################
# UserData: GitHub org-level self-hosted runner bootstrap
# - Fetch PAT from SSM SecureString (var.ssm_pat_param_name)
# - Register runner to org (var.github_org)
# - Labels include "monitoring,linux,x64"
# - Install as systemd service and auto-start
#
# IMPORTANT:
# - Do NOT embed bash heredoc with ${...} expansions directly in HCL
# - Use templatefile() with an external .tpl to avoid HCL parsing errors
############################################

locals {
  user_data = templatefile("${path.module}/userdata_runner.sh.tpl", {
    ORG            = var.github_org
    SSM_PARAM_NAME = var.ssm_pat_param_name
    RUNNER_LABELS  = "self-hosted"
  })
}

############################################
# Monitoring EC2
############################################
=======
locals {
  user_data = <<-EOT
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/monitoring

    cat > /opt/monitoring/prometheus.yml <<'YAML'
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]
    YAML

    cat > /opt/monitoring/docker-compose.yml <<'YAML'
    services:
      prometheus:
        image: prom/prometheus
        ports:
          - "9090:9090"
        volumes:
          - /opt/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro

      grafana:
        image: grafana/grafana
        ports:
          - "3000:3000"
    YAML

    cd /opt/monitoring
    docker compose up -d
  EOT
}
>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  key_name  = var.key_name
  user_data = local.user_data

<<<<<<< HEAD
  # Always attach existing IAM instance profile
  iam_instance_profile = data.aws_iam_instance_profile.read_tags_for_ansible.name

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }
}
=======
  tags = {
    Name = "${var.project_name}-monitoring"
  }
}

>>>>>>> 02ddefc (feat: Week1 Day1 - VPC, Subnet, IGW, Monitoring EC2 with Terraform)
