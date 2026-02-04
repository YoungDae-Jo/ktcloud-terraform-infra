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

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-sg-monitoring"
  description = "Monitoring SG (Grafana/Prometheus/SSH)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
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

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  key_name  = var.key_name
  user_data = local.user_data

  tags = {
    Name = "${var.project_name}-monitoring"
  }
}

