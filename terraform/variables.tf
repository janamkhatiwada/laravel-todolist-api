variable "ami_id" {
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
