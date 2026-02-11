locals {
  node_exporter_user_data = <<-EOT
#!/bin/bash
set -euo pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "unsupported arch: $ARCH" && exit 1 ;;
esac

VER="1.7.0"
cd /tmp
curl -fsSL -o node_exporter.tar.gz "https://github.com/prometheus/node_exporter/releases/download/v$${VER}/node_exporter-$${VER}.linux-$${ARCH}.tar.gz"
tar -xzf node_exporter.tar.gz
sudo install -m 0755 "node_exporter-$${VER}.linux-$${ARCH}/node_exporter" /usr/local/bin/node_exporter

sudo useradd -r -s /usr/sbin/nologin node_exporter || true

sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'UNIT'
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
EOT

  merged_user_data = trimspace(join("\n\n", compact([
    trimspace(var.user_data),
    trimspace(local.node_exporter_user_data),
  ])))
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.service_sg_id]

  key_name  = var.key_name
  user_data = local.merged_user_data != "" ? base64encode(local.merged_user_data) : null

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }
  # key_name is optional (SSM-only environments may set null)
  key_name = var.key_name

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name             = "${var.name}-service"
      Role             = "asg"
      PrometheusScrape = "true"
      Name = "${var.name}-service"
      Role             = "service"
      PrometheusScrape = "true"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.name}-service"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.private_subnet_ids

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  target_group_arns = var.target_group_arns

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 60

  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${var.name}-service"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "asg"
    value               = "service"
    propagate_at_launch = true
  }

  tag {
    key                 = "PrometheusScrape"
    value               = "true"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 60
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

