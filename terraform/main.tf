provider "aws" {
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}

module "iam_role" {
  source = "./modules/iam_role"
  kms_key_arn = module.kms.kms_key_arn
}

# Create the KMS Key with an alias for encryption
module "kms" {
  source      = "./modules/kms"
  key_alias   = "alias/mysql_root_key"
  description = "KMS key for encrypting MySQL root password and key pair in Secrets Manager"
}

# Generate key pair and store secrets in Secrets Manager
module "key_pair" {
  source      = "./modules/key_pair"
  key_name    = "web_server_key"
  kms_key_id  = module.kms.kms_key_id
  secret_name = "prod/web_server_key"
}

# Security Group Module
module "security_group" {
  source = "./modules/security_group"
}

# Compute Module for EC2 instance provisioning
module "compute" {
  source             = "./modules/compute"
  instance_type      = "t2.micro"
  key_name           = module.key_pair.key_name
  ami_id             = var.ami_id
  security_group_id  = module.security_group.id
  ssh_private_key    = module.key_pair.private_key_path
  mysql_root_password = module.key_pair.mysql_root_password_secret_arn
  iam_role_name      = module.iam_role.secrets_manager_role_name 

}

output "server_ip" {
  value = module.compute.public_ip
}
