# Terraform Configuration for EKS Dapr Microservices

This Terraform configuration provisions all AWS infrastructure needed for the EKS Dapr microservices demo, including:

- VPC with public subnets
- EKS cluster with managed node groups
- IAM roles and policies for IRSA
- ECR repositories for container images
- SNS/SQS for pub/sub messaging
- DynamoDB for state storage
- Dapr installation via Helm
- Kubernetes namespace and service account

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.27

## Directory Structure

```
terraform/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── vpc.tf                     # VPC configuration
├── eks.tf                     # EKS cluster configuration
├── iam.tf                     # IAM roles and policies
├── ecr.tf                     # ECR repositories
├── aws-resources.tf           # SNS, SQS, DynamoDB
├── kubernetes.tf              # Kubernetes resources
├── helm.tf                    # Helm releases (Dapr, metrics-server)
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Terraform ignore file
└── README.md                  # This file
```

## Usage

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Create Variables File

Copy the example and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired values.

### 3. Plan Infrastructure

```bash
terraform plan
```

### 4. Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Configure kubectl

After successful apply, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name dapr-demo-cluster
```

Or use the output command:

```bash
$(terraform output -raw configure_kubectl)
```

### 6. Verify Installation

Check EKS cluster:

```bash
kubectl get nodes
kubectl get pods -n dapr-system
kubectl get pods -n dapr-demo
```

## Important Outputs

After applying, Terraform will output:

- `cluster_endpoint`: EKS cluster API endpoint
- `cluster_name`: Name of the EKS cluster
- `ecr_repositories`: ECR repository URLs for pushing images
- `sns_topic_arn`: ARN of SNS topic
- `sqs_queue_url`: URL of SQS queue
- `dynamodb_table_name`: Name of DynamoDB table
- `dapr_service_account_role_arn`: IAM role ARN for Dapr pods
- `configure_kubectl`: Command to configure kubectl

## Deploying Applications

After infrastructure is provisioned:

1. Build and push Docker images to ECR
2. Apply Dapr components
3. Deploy microservices

```bash
# Get ECR registry URL
ECR_REGISTRY=$(terraform output -json ecr_repositories | jq -r '.["product-service"]' | cut -d'/' -f1)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push images
cd ../product-service
docker build --platform linux/amd64 -t product-service:latest .
docker tag product-service:latest $ECR_REGISTRY/product-service:latest
docker push $ECR_REGISTRY/product-service:latest

cd ../order-service
docker build --platform linux/amd64 -t order-service:latest .
docker tag order-service:latest $ECR_REGISTRY/order-service:latest
docker push $ECR_REGISTRY/order-service:latest

# Apply Dapr components and deployments
cd ..
kubectl apply -f dapr/
kubectl apply -f k8s/
```

## Cost Considerations

This configuration creates resources that incur costs:

- **EKS Cluster**: ~$0.10/hour (~$72/month)
- **EC2 Instances** (t3.medium × 2): ~$0.0416/hour each (~$60/month total)
- **NAT Gateway**: Not used (cost-optimized)
- **DynamoDB**: Pay per request
- **SNS/SQS**: Pay per request
- **ECR**: Storage costs

**Estimated monthly cost**: ~$75-100 USD (may vary by usage)

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/ --ignore-not-found=true
kubectl delete -f dapr/ --ignore-not-found=true

# Then destroy Terraform resources
terraform destroy
```

Type `yes` when prompted.

**Note**: Ensure all Kubernetes resources are deleted before running destroy, especially:
- Load Balancers (created by K8s Services)
- EBS volumes (created by PVCs)

## Variables

### Required Variables

None - all variables have defaults in `variables.tf`

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `dapr-demo-cluster` |
| `node_instance_type` | EC2 instance type | `t3.medium` |
| `node_desired_capacity` | Desired node count | `2` |
| `kubernetes_version` | Kubernetes version | `1.31` |
| `dapr_version` | Dapr Helm chart version | `1.12` |
| `namespace` | Kubernetes namespace | `dapr-demo` |
| `sns_topic_name` | SNS topic name | `orders` |
| `dynamodb_table_name` | DynamoDB table name | `dapr-state-table` |

See [variables.tf](variables.tf) for full list.

## Modules Used

This configuration uses official Terraform modules:

- [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)

## Troubleshooting

### Error: Cluster already exists

If you see conflicts, check for existing clusters:

```bash
aws eks list-clusters --region us-east-1
```

### Error: VPC already exists

Check for existing VPCs with the same name tag:

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dapr-demo-cluster-vpc"
```

### Kubectl connection issues

Ensure your kubeconfig is updated:

```bash
aws eks update-kubeconfig --region us-east-1 --name dapr-demo-cluster
```

### Terraform state issues

If you need to refresh state:

```bash
terraform refresh
```

## State Management

For production use, configure remote state backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "eks-dapr-demo/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Security Considerations

1. **Credentials**: Never commit `terraform.tfvars` with sensitive data
2. **State Files**: Store Terraform state securely (use S3 + DynamoDB)
3. **IAM Policies**: Review and restrict IAM policies for production
4. **Network**: Consider using private subnets for production
5. **Encryption**: Enable encryption for ECR, EBS, and DynamoDB

## Comparison with Shell Scripts

| Feature | Shell Script | Terraform |
|---------|-------------|-----------|
| **Idempotent** | ❌ Requires manual checks | ✅ Automatic state management |
| **Rollback** | ❌ Manual cleanup | ✅ `terraform destroy` |
| **Drift Detection** | ❌ No detection | ✅ `terraform plan` shows drift |
| **Modular** | ❌ Monolithic script | ✅ Separate files per resource |
| **Dependencies** | ⚠️ Manual ordering | ✅ Automatic dependency graph |
| **State Management** | ❌ No state tracking | ✅ Terraform state file |

## License

This configuration is for educational purposes as part of Cloud Native Applications Lab 2.
