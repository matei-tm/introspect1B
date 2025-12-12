# Get current caller identity
data "aws_caller_identity" "current" {}

# IAM Policy for EKS Full Admin Access
data "aws_iam_policy_document" "eks_full_admin_access" {
  statement {
    effect = "Allow"
    actions = [
      "eks:*"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com"]
    }
  }

  # Add KMS permissions needed for EKS cluster encryption
  statement {
    effect = "Allow"
    actions = [
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:EnableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateAlias",
      "kms:UpdateKeyDescription"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_full_admin_access" {
  name        = "EKSFullAdminAccess"
  description = "Full admin access to all EKS clusters including KMS operations"
  policy      = data.aws_iam_policy_document.eks_full_admin_access.json

  tags = {
    Name = "EKSFullAdminAccess"
  }
}

# IAM Policy for EC2 Instance Type Access
data "aws_iam_policy_document" "ec2_instance_type_access" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceType"
      values = [
        "t2.micro",
        "t3.medium"
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_instance_type_access" {
  name        = "EC2InstanceTypeAccess"
  description = "Allow launching t2.micro and t3.medium instances"
  policy      = data.aws_iam_policy_document.ec2_instance_type_access.json

  tags = {
    Name = "EC2InstanceTypeAccess"
  }
}

# IAM Policy for Dapr Service Account
data "aws_iam_policy_document" "dapr_service_account" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
      "sns:Subscribe",
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:ListTopics",
      "sns:GetTopicAttributes",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:ListSubscriptionsByTopic"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:ListQueues",
      "sqs:SetQueueAttributes"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:DescribeTable",
      "dynamodb:CreateTable"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dapr_service_account" {
  name        = "DaprServiceAccountPolicy"
  description = "Policy for Dapr to access SNS, SQS, and DynamoDB"
  policy      = data.aws_iam_policy_document.dapr_service_account.json
}

# IAM Role for Dapr Service Account (IRSA)
resource "aws_iam_role" "dapr_service_account" {
  name = "DaprServiceAccountRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:dapr-service-account"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "DaprServiceAccountRole"
  }
}

resource "aws_iam_role_policy_attachment" "dapr_service_account" {
  policy_arn = aws_iam_policy.dapr_service_account.arn
  role       = aws_iam_role.dapr_service_account.name
}

# Get current IAM user name from ARN
locals {
  caller_arn_parts = split("/", data.aws_caller_identity.current.arn)
  caller_user_name = element(local.caller_arn_parts, length(local.caller_arn_parts) - 1)
}

# Attach EKS admin policy to current user
resource "aws_iam_user_policy_attachment" "eks_full_admin_access" {
  count = var.attach_ec2_policy_to_current_user ? 1 : 0

  user       = local.caller_user_name
  policy_arn = aws_iam_policy.eks_full_admin_access.arn
}

# Attach EC2 policy to current user (optional)
resource "aws_iam_user_policy_attachment" "ec2_instance_type_access" {
  count = var.attach_ec2_policy_to_current_user ? 1 : 0

  user       = local.caller_user_name
  policy_arn = aws_iam_policy.ec2_instance_type_access.arn
}
