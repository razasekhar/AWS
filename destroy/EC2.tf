provider "aws" {
    region = "us-east-2"
  
}


# Create an AWS Backup vault in the backup region
resource "aws_backup_vault" "dynamodb_backup_vault" {
  name        = "dynamodb-backup-vault"
  kms_key_arn = aws_kms_key.backup_key[0].arn
}

# Create a KMS key for encrypting backups
resource "aws_kms_key" "backup_key" {
  description             = "KMS key for DynamoDB backups"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Create an AWS Backup plan
resource "aws_backup_plan" "dynamodb_backup_plan" {
  name = "dynamodb-backup-plan"

  rule {
    rule_name         = "daily-dynamodb-backup"
    target_vault_name = aws_backup_vault.dynamodb_backup_vault.name
    schedule          = "cron(0 3 * * ? *)" # Daily backups at 3 AM UTC
    lifecycle {
      delete_after = 30 # Retain backups for 30 days
    }
  }
}

# Create an AWS Backup selection for the DynamoDB table
resource "aws_backup_selection" "dynamodb_backup_selection" {
  name         = "dynamodb-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.dynamodb_backup_plan.id

  resources = [
    aws_dynamodb_table.example_dynamodb_table.arn
  ]
}

# Create a DynamoDB table (for demonstration)
resource "aws_dynamodb_table" "example_dynamodb_table" {
  name           = "example-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Create an IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "dynamodb-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "dynamodb_backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForDynamoDBBackup"
  role       = aws_iam_role.backup_role.name
}
