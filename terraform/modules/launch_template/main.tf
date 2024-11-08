resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  ebs_optimized = true

  # IAM instance profile for Secrets Manager access
  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # AMI ID for the instance
  image_id = var.ami_id

  # Define shutdown behavior for the instance
  instance_initiated_shutdown_behavior = "terminate"

  # Instance type
  instance_type = var.instance_type

  # SSH key pair
  key_name = var.key_name

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # Network interface settings
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]  # Move security group here
  }

  # Tag specifications
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "Prod Laravel Server"
      Environment = var.environment
    }
  }

  # Load user_data script from a local file, encoding it to Base64
  user_data = filebase64("${path.root}/provisioner/install_dependencies.sh")
}

# Output to retrieve the launch template ID
output "launch_template_id" {
  value = aws_launch_template.web_lt.id
}
