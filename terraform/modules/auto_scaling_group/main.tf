resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids
  
  launch_template {
    id      = var.launch_template_id
    version = "11"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  instance_refresh {
    strategy = "Rolling"
  
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300  # Waits 5 minutes before checking health
    }
  
    triggers = ["launch_template"]
  }
  tag {
    key                 = "Name"
    value               = "Laravel Prod Application Server"
    propagate_at_launch = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}
