variable "launch_template_name" {
  description = "Name of the launch template"
  type        = string
  default     = "web-launch-template"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
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
