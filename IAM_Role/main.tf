# Provider configuration
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Define IAM user names
locals {
  user_names = ["user1", "user2", "user3", "user4"]
}

# IAM Role with EC2 and S3 full access
resource "aws_iam_role" "ec2_s3_full_access_role" {
  name = "EC2_S3_FullAccess_Role"

  # Trust policy allowing IAM users to assume this role
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            for user in aws_iam_user.users : user.arn  # Include each user's ARN
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach EC2 Full Access Policy to the role
resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.ec2_s3_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Attach S3 Full Access Policy to the role
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_s3_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create IAM Users dynamically with different names
resource "aws_iam_user" "users" {
  for_each = toset(local.user_names)
  name = each.key
}

