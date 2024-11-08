variable "vpc_id" {
  description = "VPC ID for the load balancer"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the load balancer"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the load balancer"
  type        = list(string)
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}
