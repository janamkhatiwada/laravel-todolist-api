data "aws_caller_identity" "current" {}

resource "aws_kms_key" "laravel" {
  description             = var.description
  enable_key_rotation     = true
  deletion_window_in_days = 20

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowAllUsersAdministration"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
        Condition = {
          "StringEquals": {
            "aws:PrincipalAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Sid    = "AllowSecretsManagerRoleDecrypt",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/secrets-manager-access-role"
        },
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

# alias for the KMS key
resource "aws_kms_alias" "laravel_alias" {
  name          = var.key_alias
  target_key_id = aws_kms_key.laravel.id
}

output "kms_key_id" {
  value = aws_kms_key.laravel.id
}

output "kms_key_alias" {
  value = aws_kms_alias.laravel_alias.name
}
output "kms_key_arn" {
  value = aws_kms_key.laravel.arn
}