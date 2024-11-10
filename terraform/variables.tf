variable "base_ami_id" {
  default = "ami-0866a3c8686eaeeba" # ubuntu
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "laravel-prod-app-key"
}

variable "ssh_private_key_path" {
  default = "~/.ssh/test"
}

variable "ami_id_override" {
  default = "ami-0c5dbb280cb5ee8a2"
}
variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"  # Set a default or provide it during `terraform apply`
}