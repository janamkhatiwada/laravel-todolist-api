variable "secret_name" {
  description = "Base name of the secret in Secrets Manager"
  type        = string
}

variable "kms_key_id" {
  description = "The ID of the KMS key used to encrypt the secret"
  type        = string
}

variable "private_key" {
  description = "The private key content to be stored"
  type        = string
}

variable "public_key" {
  description = "The public key content to be stored"
  type        = string
}

variable "mysql_root_password" {
  description = "The MySQL root password to be stored in Secrets Manager"
  type        = string
}
