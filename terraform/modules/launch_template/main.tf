resource "aws_instance" "provisioning_instance" {
  ami                    = var.base_ami_id  # Base Ubuntu AMI
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id  # Use a public subnet ID for provisioning
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  iam_instance_profile = var.iam_instance_profile_name
  
  tags = {
    Name = "AMI Prod Application Server"
  }
  lifecycle {
    create_before_destroy = false
  }  
  # First, upload the script using file provisioner
  provisioner "file" {
    source      = "${path.root}/provisioner/install_dependencies.sh"  # Local path to the script
    destination = "/tmp/install_dependencies.sh"  # Remote path to store the script
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }

  # Then, execute the script on the remote instance
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }

    # Execute the uploaded script
    inline = [
      "chmod +x /tmp/install_dependencies.sh",
      "bash /tmp/install_dependencies.sh"
    ]
  }
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.region}"
  }  
}

# Create AMI from the Provisioned Instance
resource "aws_ami_from_instance" "web_ami" {
  name               = "${var.environment}-web-ami"
  source_instance_id = aws_instance.provisioning_instance.id
  depends_on         = [aws_instance.provisioning_instance]

  tags = {
    Name = "${var.environment}-web-ami"
  }
}

# Conditionally read last_ami_id.txt only if it exists
locals {
  last_ami_id_path = "${path.root}/last_ami_id.txt"
}

data "local_file" "last_ami_id" {
  count    = fileexists(local.last_ami_id_path) ? 1 : 0
  filename = local.last_ami_id_path
}

# Determine AMI ID for Launch Template
# Use the override if provided, otherwise use the last saved AMI ID, or fall back to the new AMI
locals {
  launch_template_ami_id = var.ami_id_override != "" ? var.ami_id_override : (
    length(data.local_file.last_ami_id) > 0 ? data.local_file.last_ami_id[0].content : aws_ami_from_instance.web_ami.id
  )
}

# Save the AMI ID to a local file for reuse in future runs
resource "local_file" "ami_id_file" {
  content  = aws_ami_from_instance.web_ami.id
  filename = local.last_ami_id_path
}

# Launch Template Configuration
resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  ebs_optimized = true

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  image_id = local.launch_template_ami_id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type                       = var.instance_type
  key_name                            = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "Prod Laravel Server"
      Environment = var.environment
    }
  }
}

output "new_ami_id" {
  description = "The newly created AMI ID"
  value       = aws_ami_from_instance.web_ami.id
}
output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.web_lt.id
}