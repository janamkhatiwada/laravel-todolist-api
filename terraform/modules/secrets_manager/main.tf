# private key in Secrets Manager
resource "aws_secretsmanager_secret" "private_key" {
  name        = "${var.secret_name}/private_key"
  description = "Private key for the web server"
  kms_key_id  = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "private_key_version" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = var.private_key
}

# public key in Secrets Manager
resource "aws_secretsmanager_secret" "public_key" {
  name        = "${var.secret_name}/public_key"
  description = "Public key for the web server"
  kms_key_id  = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "public_key_version" {
  secret_id     = aws_secretsmanager_secret.public_key.id
  secret_string = var.public_key
}

# MySQL root password in Secrets Manager
resource "aws_secretsmanager_secret" "mysql_root_password" {
  name        = "${var.secret_name}/mysql_root_password"
  description = "MySQL root password for the Laravel server"
  kms_key_id  = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "mysql_root_password_version" {
  secret_id     = aws_secretsmanager_secret.mysql_root_password.id
  secret_string = var.mysql_root_password
}

output "private_key_secret_arn" {
  value = aws_secretsmanager_secret.private_key.arn
}

output "public_key_secret_arn" {
  value = aws_secretsmanager_secret.public_key.arn
}

output "mysql_root_password_secret_arn" {
  value = aws_secretsmanager_secret.mysql_root_password.arn
}
