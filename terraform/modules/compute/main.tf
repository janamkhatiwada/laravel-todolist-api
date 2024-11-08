resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.secrets_manager_instance_profile.name
  
  tags = {
    Name = "Laravel Prod Application Server"
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
      "MYSQL_ROOT_PASSWORD=${var.mysql_root_password} bash /tmp/install_dependencies.sh"
    ]
  }
}

resource "aws_iam_instance_profile" "secrets_manager_instance_profile" {
  name = "secrets-manager-instance-profile"
  role = var.iam_role_name
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
