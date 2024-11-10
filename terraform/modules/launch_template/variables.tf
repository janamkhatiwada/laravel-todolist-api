variable "launch_template_name" {
  description = "Name of the launch template"
  type        = string
  default     = "web-launch-template"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "base_ami_id" {
  description = "AMI ID for the instances"
  type        = string
}

variable "key_name" {
  description = "Key name for SSH access"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the instances"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "mysql_root_password_secret_arn" {
  description = "Secret ARN for the MySQL root password"
  type        = string
}
variable "ami_id_override" {
  description = "Optionally specify a custom AMI ID for the launch template. If not provided, the last used AMI ID is used."
  type        = string
  default     = ""
}
variable "subnet_id" {
  description = "List of subnet IDs for the AMI"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}
variable "ssh_private_key" {
  description = "Path to the SSH private key for connecting to the instance"
  type        = string
}