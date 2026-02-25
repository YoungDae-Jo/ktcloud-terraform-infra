resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.service_sg_id]

  key_name  = var.key_name
  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name             = "${var.name}-service"
      Role             = "asg"
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
    propagate_at_launch = true
  }

  tag {
    key                 = "PrometheusScrape"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

