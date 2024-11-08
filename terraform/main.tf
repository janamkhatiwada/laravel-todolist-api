provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
terraform {
  backend "s3" {
    bucket  = "test-tf-bucket-0001"
    key     = "prod.tfstate"
    region  = "us-east-1"
  }
}
# Networking Module for VPC, Subnets, and NAT Gateway
module "networking" {
  source              = "./modules/networking_module"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  environment         = "prod"
}

# IAM Role for Secrets Manager Access
module "iam_role" {
  source      = "./modules/iam_role"
  kms_key_arn = module.kms.kms_key_arn
}

# KMS Module for Secrets Encryption
module "kms" {
  source      = "./modules/kms"
  key_alias   = "alias/mysql_root_key"
  description = "KMS key for encrypting MySQL root password and key pair in Secrets Manager"
}

# Key Pair Module for SSH Access
module "key_pair" {
  source      = "./modules/key_pair"
  key_name    = "web_server_key"
  kms_key_id  = module.kms.kms_key_id
  secret_name = "production/web_server_key"
}

# Security Group Module linked to VPC
module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.networking.vpc_id
}

# IAM Instance Profile for Accessing Secrets Manager
resource "aws_iam_instance_profile" "secrets_manager_instance_profile" {
  name = "secrets-manager-instance-profile"
  role = module.iam_role.secrets_manager_role_name
}

# Launch Template for Private Subnet Instances
module "launch_template" {
  source                     = "./modules/launch_template"
  launch_template_name       = "web-lt"
  instance_type              = var.instance_type
  ami_id                     = var.ami_id
  key_name                   = module.key_pair.key_name
  security_group_id          = module.security_group.id
  iam_instance_profile_name  = aws_iam_instance_profile.secrets_manager_instance_profile.name
  mysql_root_password_secret_arn = module.key_pair.mysql_root_password_secret_arn
  environment                = "prod"
}

# Auto Scaling Group for Private Subnet Instances
module "auto_scaling_group" {
  source             = "./modules/auto_scaling_group"
  desired_capacity   = 2
  max_size           = 4
  min_size           = 1
  subnet_ids         = module.networking.private_subnet_ids
  launch_template_id = module.launch_template.launch_template_id
}

# Load Balancer and Target Group for High Availability
module "load_balancer" {
  source              = "./modules/load_balancer"
  vpc_id              = module.networking.vpc_id
  security_group_id   = module.security_group.id
  public_subnet_ids   = module.networking.public_subnet_ids
  asg_name            = module.auto_scaling_group.asg_name
  environment         = "prod"
}

# Outputs
output "load_balancer_dns" {
  value = module.load_balancer.lb_dns_name
}

output "asg_name" {
  value = module.auto_scaling_group.asg_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}
