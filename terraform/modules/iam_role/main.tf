data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Create IAM Role
resource "aws_iam_role" "secrets_manager_role" {
  name               = "secrets-manager-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM Policy for accessing Secrets Manager and decrypting with KMS
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "secrets-manager-access-policy"
  description = "Policy to allow access to Secrets Manager and decrypting with KMS"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:prod/env-*"
      },
      {
        Effect = "Allow"
        Action = "kms:Decrypt"
        Resource = var.kms_key_arn  # KMS key used for Secrets Manager encryption
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_secrets_manager_policy" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

output "secrets_manager_role_name" {
  value = aws_iam_role.secrets_manager_role.name
}
