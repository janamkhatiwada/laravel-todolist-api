variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "kms_key_id" {
  description = "The ID of the KMS key used to encrypt the secret"
  type        = string
}

variable "secret_name" {
  description = "Base name of the secret in Secrets Manager"
  type        = string
  default     = "prod/web_server_key"
}
