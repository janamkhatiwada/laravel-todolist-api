variable "ami_id" {
  description = "The Amazon Machine Image (AMI) ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the server"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The SSH key name to access the instance"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the instance"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH private key for connecting to the instance"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
}
variable "iam_role_name" {
  description = "IAM role name for accessing Secrets Manager"
  type        = string
}
