variable "desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum size of the ASG"
  type        = number
}

variable "min_size" {
  description = "Minimum size of the ASG"
  type        = number
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG"
  type        = list(string)
}

variable "launch_template_id" {
  description = "Launch template ID for ASG instances"
  type        = string
}
