output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.orders.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue for order service"
  value       = aws_sqs_queue.orders_subscriber.url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.dapr_state.name
}

output "dapr_service_account_role_arn" {
  description = "ARN of the IAM role for Dapr service account"
  value       = aws_iam_role.dapr_service_account.arn
}

output "eks_full_admin_access_policy_arn" {
  description = "ARN of the EKS full admin access policy"
  value       = aws_iam_policy.eks_full_admin_access.arn
}

output "ec2_instance_type_access_policy_arn" {
  description = "ARN of the EC2 instance type access policy"
  value       = aws_iam_policy.ec2_instance_type_access.arn
}

output "current_iam_user" {
  description = "Current IAM user name"
  value       = local.caller_user_name
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "cloudwatch_log_group_application" {
  description = "CloudWatch Logs group for application logs"
  value       = "/aws/containerinsights/${var.cluster_name}/application"
}

output "cloudwatch_log_group_cluster" {
  description = "CloudWatch Logs group for cluster control plane logs"
  value       = "/aws/eks/${var.cluster_name}/cluster"
}

output "cloudwatch_agent_role_arn" {
  description = "ARN of the IAM role for CloudWatch agent"
  value       = aws_iam_role.cloudwatch_agent.arn
}

output "fluent_bit_role_arn" {
  description = "ARN of the IAM role for Fluent Bit"
  value       = aws_iam_role.fluent_bit.arn
}
