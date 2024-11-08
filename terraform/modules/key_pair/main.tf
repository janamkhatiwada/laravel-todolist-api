resource "random_password" "mysql_root_password" {
  length  = 32
  special = false
}

# private key locally
resource "tls_private_key" "web_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "web_server_key" {
  key_name   = var.key_name
  public_key = tls_private_key.web_server_key.public_key_openssh
}

# Save the private key locally for SSH access
#resource "local_file" "private_key" {
#  content  = tls_private_key.web_server_key.private_key_pem
#  filename = "${path.module}/id_rsa_${var.key_name}.pem"
#}

resource "null_resource" "chmod_key" {
  provisioner "local-exec" {
    command = "chmod 400 ${local_file.private_key.filename}"
  }

  depends_on = [local_file.private_key]
}

module "store_keys_in_secrets" {
  source             = "../secrets_manager"
  secret_name        = var.secret_name
  kms_key_id         = var.kms_key_id
  private_key        = tls_private_key.web_server_key.private_key_pem
  public_key         = tls_private_key.web_server_key.public_key_openssh
  mysql_root_password = random_password.mysql_root_password.result
}

output "key_name" {
  value = aws_key_pair.web_server_key.key_name
}

output "private_key_path" {
  value = local_file.private_key.filename
}

output "private_key_secret_arn" {
  value = module.store_keys_in_secrets.private_key_secret_arn
}

output "public_key_secret_arn" {
  value = module.store_keys_in_secrets.public_key_secret_arn
}

output "mysql_root_password_secret_arn" {
  value = module.store_keys_in_secrets.mysql_root_password_secret_arn
}

output "generated_mysql_root_password" {
  value       = random_password.mysql_root_password.result
  sensitive   = true
  description = "The generated MySQL root password"
}
