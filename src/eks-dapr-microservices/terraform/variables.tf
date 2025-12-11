variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "dapr-demo-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "dapr_version" {
  description = "Dapr Helm chart version"
  type        = string
  default     = "1.12"
}

variable "namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
  default     = "dapr-demo"
}

variable "ecr_repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["product-service", "order-service"]
}

variable "sns_topic_name" {
  description = "SNS topic name for pub/sub"
  type        = string
  default     = "orders"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state store"
  type        = string
  default     = "dapr-state-table"
}

variable "attach_ec2_policy_to_current_user" {
  description = "Whether to attach EC2InstanceTypeAccess policy to the current IAM user"
  type        = bool
  default     = true
}
