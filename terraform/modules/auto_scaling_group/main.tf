resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "Laravel Prod Application Server"
    propagate_at_launch = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}
