# Cloud Native Applications - Lab 2: EKS Dapr Microservices

A complete demonstration of containerized microservices deployed on Amazon EKS with Dapr sidecars implementing pub/sub messaging patterns using AWS SNS/SQS for real-time event-driven interactions.

## 📋 Overview

This project demonstrates:
- **Amazon EKS**: Managed Kubernetes cluster for container orchestration
- **Dapr**: Distributed Application Runtime for microservices
- **Pub/Sub Messaging**: Event-driven communication using AWS SNS/SQS
- **AWS DynamoDB**: State store for Dapr
- **IRSA**: IAM Roles for Service Accounts for secure AWS access
- **Infrastructure as Code**: Terraform for complete infrastructure provisioning
- **CI/CD**: GitHub Actions workflows for automated deployment
- **Real-time Observability**: Live monitoring of message flows

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Amazon EKS Cluster                         │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Namespace: dapr-demo                          │ │
│  │                                                            │ │
│  │   ┌──────────────────┐         ┌──────────────────┐        │ │
│  │   │  Product Pod     │         │   Order Pod      │        │ │
│  │   │  ┌────────────┐  │         │  ┌────────────┐  │        │ │
│  │   │  │  Product   │  │         │  │   Order    │  │        │ │
│  │   │  │  Service   │  │         │  │  Service   │  │        │ │
│  │   │  │ (Node.js)  │  │         │  │ (Node.js)  │  │        │ │
│  │   │  └────────────┘  │         │  └────────────┘  │        │ │
│  │   │        ↓         │         │        ↑         │        │ │
│  │   │  ┌────────────┐  │         │  ┌────────────┐  │        │ │
│  │   │  │   Dapr     │  │         │  │   Dapr     │  │        │ │
│  │   │  │  Sidecar   │  │         │  │  Sidecar   │  │        │ │
│  │   │  └─────┬──────┘  │         │  └──────┬─────┘  │        │ │
│  │   └────────┼─────────┘         └─────────┼────────┘        │ │
│  │            │                             │                 │ │
│  │            │   (IRSA Authentication)     │                 │ │
│  └────────────┼─────────────────────────────┼─────────────────┘ │
│               │                             │                   │
│               ↓                             ↓                   │
└───────────────┼─────────────────────────────┼───────────────────┘
                │                             │
         ┌──────▼──────┐             ┌────────▼───────┐
         │   AWS SNS   │────────────►│   AWS SQS      │
         │   (Topic)   │             │   (Queue)      │
         │   orders    │             │    order       │
         └─────────────┘             └────────────────┘
                                              │
         ┌────────────────────────────────────┘
         │
         ▼
  ┌─────────────┐
  │  DynamoDB   │
  │ (State)     │
  └─────────────┘
```

## 🔑 Key Features

### Product Service
- Automatically publishes order messages every 5 seconds
- Uses Dapr HTTP API to publish to AWS SNS topic
- Generates realistic order data (order ID, customer, product, etc.)
- Health check endpoint for Kubernetes probes
- Deployed with manual Dapr sidecar injection

### Order Service
- Subscribes to order messages via Dapr pub/sub from AWS SQS
- Implements Dapr subscription endpoint (`/dapr/subscribe`)
- Processes incoming orders with simulated business logic
- Tracks and displays received messages
- Supports multiple replicas (2 by default) for load distribution
- Uses IRSA for secure AWS access without credentials

### Infrastructure Management
- **Terraform**: Complete infrastructure as code
- **Two-stage deployment**: Infrastructure provisioning + service deployment
- **GitHub Actions**: Automated workflows for CI/CD
- **Local simulation**: Development-friendly deployment scripts
- **Cost-optimized**: Uses public subnets, no NAT Gateway

## 📦 Repository Structure

```
.
├── src/
│   ├── eks-dapr-microservices/
│   │   ├── product-service/
│   │   │   ├── app.js              # Product service application
│   │   │   ├── package.json        # Dependencies
│   │   │   └── Dockerfile          # Container image
│   │   ├── order-service/
│   │   │   ├── app.js              # Order service application
│   │   │   ├── package.json        # Dependencies
│   │   │   └── Dockerfile          # Container image
│   │   ├── terraform/
│   │   │   ├── main.tf             # Main Terraform configuration
│   │   │   ├── vpc.tf              # VPC and networking
│   │   │   ├── eks.tf              # EKS cluster configuration
│   │   │   ├── iam.tf              # IAM roles and policies (IRSA)
│   │   │   ├── ecr.tf              # ECR repositories
│   │   │   ├── aws-resources.tf    # SNS, SQS, DynamoDB
│   │   │   ├── kubernetes.tf       # Kubernetes resources
│   │   │   ├── helm.tf             # Dapr and Metrics Server
│   │   │   ├── variables.tf        # Input variables
│   │   │   ├── outputs.tf          # Output values
│   │   │   └── terraform.tfvars.example
│   │   ├── k8s/
│   │   │   ├── dapr-rbac.yaml           # RBAC for Dapr
│   │   │   ├── product-deployment.yaml  # Product deployment
│   │   │   ├── product-service.yaml     # Product service
│   │   │   ├── order-deployment.yaml    # Order deployment
│   │   │   └── order-service.yaml       # Order service
│   │   ├── dapr/
│   │   │   ├── pubsub.yaml         # Dapr pub/sub (AWS SNS/SQS)
│   │   │   ├── statestore.yaml     # Dapr state store (DynamoDB)
│   │   │   └── configuration.yaml  # Dapr configuration
│   │   ├── .github/workflows/
│   │   │   ├── terraform-deploy.yml     # Infrastructure workflow
│   │   │   └── deploy-services.yml      # Service deployment workflow
│   │   └── scripts/
│   │       ├── simulate-github-deploy.sh    # Local deployment simulation
│   │       ├── simulate-github-start-lab.sh # Lab verification
│   │       └── cleanup.sh                   # Resource cleanup
│   └── labinit/
│       ├── tests/
│       │   └── vlabs.spec.js       # Playwright test for lab initialization
│       ├── playwright.config.js
│       ├── package.json
│       └── run-tests.ps1
└── README.md                       # This file
```

## 🚀 Prerequisites

Before starting, ensure you have:

- **AWS CLI** (v2.x): [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (~> 1.0): [Installation Guide](https://developer.hashicorp.com/terraform/install)
- **kubectl** (v1.27+): [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker**: [Installation Guide](https://docs.docker.com/get-docker/)
- **AWS Account** with appropriate permissions
- **AWS credentials** configured (`aws configure`)
- **Git**: For version control and commit SHA tracking

## 📥 Quick Start

### Step 1: Deploy Infrastructure with Terraform

```bash
cd src/eks-dapr-microservices/terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply infrastructure
terraform apply
```

**Terraform will create:**
- ✅ VPC with public subnets
- ✅ EKS cluster (v1.31) with managed node group (t3.medium × 2)
- ✅ ECR repositories for product-service and order-service
- ✅ SNS topic and SQS queue for pub/sub messaging
- ✅ DynamoDB table for state store
- ✅ IAM roles with IRSA for secure AWS access
- ✅ Dapr 1.12.5 installed via Helm
- ✅ Metrics Server for resource monitoring
- ✅ Kubernetes namespace and service account

### Step 2: Deploy Services

#### Option A: Using GitHub Actions (CI/CD)

1. Push your code to GitHub
2. Configure repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Trigger the workflow:
   - **Automatic**: Push changes to `product-service/` or `order-service/`
   - **Manual**: Run workflow via GitHub Actions UI

The workflow will:
- Login to ECR
- Build Docker images for linux/amd64
- Push images to ECR
- Apply Dapr components and RBAC
- Deploy services to EKS
- Wait for rollout completion

#### Option B: Local Simulation (Development)

```bash
cd src/eks-dapr-microservices

# Deploy all services
./scripts/simulate-github-deploy.sh all

# Or deploy individual services
./scripts/simulate-github-deploy.sh product-service
./scripts/simulate-github-deploy.sh order-service
```

## 🧪 Testing and Verification

### Quick Test

```bash
cd src/eks-dapr-microservices/scripts
./simulate-github-start-lab.sh
```

### Manual Verification

#### 1. Check Pod Status

```bash
kubectl get pods -n dapr-demo
```

Expected output:
```
NAME                       READY   STATUS    RESTARTS   AGE
product-xxxxxxxxxx-xxxxx   2/2     Running   0          2m
order-xxxxxxxxxx-xxxxx     2/2     Running   0          2m
order-xxxxxxxxxx-yyyyy     2/2     Running   0          2m
```

#### 2. View End-to-End Message Flow

```bash
kubectl logs -n dapr-demo -l app=product -c product --tail=10 && \
echo "---ORDER SERVICE---" && \
kubectl logs -n dapr-demo -l app=order -c order --tail=10
```

**Expected output:**

```text
✅ Published order: order-1765506590978-44 {
  orderId: 'order-1765506590978-44',
  customerId: 'customer-277',
  product: 'laptop',
  quantity: 5,
  totalAmount: '402.29',
  timestamp: '2025-12-12T02:29:50.978Z'
}
---ORDER SERVICE---
🚀 Order service listening on port 3001
👂 Subscribed to topic: orders
📦 [27] Received order: {
  orderId: 'order-1765506595980-45',
  product: 'phone',
  quantity: 1,
  amount: '162.09',
  timestamp: '2025-12-12T02:29:55.980Z'
}
✅ Order order-1765506595980-45 processed successfully
```

#### 3. Verify Dapr Components

```bash
kubectl get components -n dapr-demo
```

Expected output:
```
NAME             AGE
messagepubsub    5m
statestore       5m
```

## 📊 Observing Real-Time Events

### Log Streaming

Watch both services simultaneously:

```bash
# Terminal 1 - Product Service
kubectl logs -f deployment/product -n dapr-demo -c product

# Terminal 2 - Order Service
kubectl logs -f deployment/order -n dapr-demo -c order
```

### Dapr Sidecar Logs

```bash
kubectl logs deployment/product -n dapr-demo -c daprd --tail=20
kubectl logs deployment/order -n dapr-demo -c daprd --tail=20
```

## 🔧 Configuration

### Terraform Variables

Key variables in `terraform/variables.tf`:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `dapr-demo-cluster` |
| `node_instance_type` | EC2 instance type | `t3.medium` |
| `node_desired_capacity` | Desired node count | `2` |
| `kubernetes_version` | Kubernetes version | `1.31` |
| `dapr_version` | Dapr Helm chart version | `1.12` |
| `namespace` | Kubernetes namespace | `dapr-demo` |

### Scaling

Scale order service replicas:

```bash
kubectl scale deployment/order -n dapr-demo --replicas=5
```

### Resource Limits

Adjust in `k8s/*-deployment.yaml`:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## 🐛 Troubleshooting

### Pods Not Starting

```bash
kubectl describe pod <pod-name> -n dapr-demo
kubectl get events -n dapr-demo --sort-by='.lastTimestamp'
```

### Dapr Sidecar Issues

```bash
kubectl logs <pod-name> -n dapr-demo -c daprd
```

### AWS Permission Issues

Check IRSA configuration:

```bash
kubectl describe sa dapr-service-account -n dapr-demo
```

Verify IAM role annotations:

```bash
kubectl get sa dapr-service-account -n dapr-demo -o yaml | grep eks.amazonaws.com/role-arn
```

### Terraform State Issues

If you need to refresh state:

```bash
cd src/eks-dapr-microservices/terraform
terraform refresh
```

## 💰 Cost Considerations

This configuration creates resources that incur costs:

- **EKS Cluster**: ~$0.10/hour (~$72/month)
- **EC2 Instances** (t3.medium × 2): ~$0.0416/hour each (~$60/month total)
- **NAT Gateway**: Not used (cost-optimized)
- **DynamoDB**: Pay per request
- **SNS/SQS**: Pay per request
- **ECR**: Storage costs

**Estimated monthly cost**: ~$75-100 USD (may vary by usage)

⚠️ **Remember to destroy resources when not in use!**

## 🧹 Cleanup

### Quick Cleanup

```bash
cd src/eks-dapr-microservices
./scripts/cleanup.sh
```

### Complete Infrastructure Cleanup

```bash
# Delete Kubernetes resources first
cd src/eks-dapr-microservices
kubectl delete -f k8s/ -n dapr-demo --ignore-not-found=true
kubectl delete configmap dapr-components -n dapr-demo --ignore-not-found=true

# Then destroy Terraform infrastructure
cd terraform
terraform destroy
```

This will remove:
- All deployed services and pods
- Dapr components and RBAC
- EKS cluster and node groups
- VPC and networking resources
- ECR repositories and images
- SNS topics and SQS queues
- DynamoDB tables
- IAM roles and policies

## 📚 Key Concepts Demonstrated

### 1. Dapr Sidecar Pattern
Each pod contains two containers:
- Application container (product/order service)
- Dapr sidecar container (handles infrastructure concerns)

### 2. Pub/Sub Messaging
- **Decoupling**: Product and order services don't know about each other
- **Scalability**: Multiple order replicas can process messages
- **Reliability**: AWS SNS/SQS ensures message delivery
- **CloudEvents**: Standard format for event data

### 3. Infrastructure as Code
- **Terraform**: Declarative infrastructure provisioning
- **Idempotent**: Safe to run multiple times
- **State Management**: Tracks infrastructure changes
- **Dependency Resolution**: Automatic resource ordering

### 4. Kubernetes Best Practices
- Health checks (liveness/readiness probes)
- Resource limits and requests
- Namespaces for isolation
- RBAC for security
- ConfigMaps for configuration

### 5. Event-Driven Architecture
- Asynchronous communication
- Real-time message processing
- Horizontal scalability
- Resilient messaging

## 📖 Learning Resources

- [Dapr Documentation](https://docs.dapr.io/)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Dapr Pub/Sub Tutorial](https://docs.dapr.io/developing-applications/building-blocks/pubsub/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🎯 Lab Objectives Met

✅ **Deploy containerized microservices on Amazon EKS**
- Product and order services containerized with Docker
- Deployed to managed EKS cluster with Terraform

✅ **Implement Dapr sidecars**
- Dapr sidecar manually injected into each pod
- Handles all pub/sub communication via AWS SNS/SQS

✅ **Pub/Sub messaging pattern**
- AWS SNS/SQS-backed pub/sub component
- Real-time event publishing and subscription
- CloudEvents format for message delivery

✅ **Observe real-time interactions**
- Live log streaming shows message flow
- Multiple order replicas demonstrate load distribution
- IRSA provides secure AWS access

✅ **Infrastructure as Code**
- Complete Terraform configuration
- Automated infrastructure provisioning
- State management and drift detection

## 🧪 Lab Initialization Tests

For automated lab verification, use the Playwright tests:

```bash
# PowerShell
cd src/labinit
$env:SITE_USER = "youruser"
$env:SITE_PASSWORD = "yourpass"
npm ci
npx playwright install --with-deps
npm test
```

**GitHub Actions**: The workflow `.github/workflows/ci.yml` uses repository secrets:
- `SITE_USER`: username
- `SITE_PASSWORD`: password

<img width="658" height="304" alt="Lab Initialization Test Results" src="https://github.com/user-attachments/assets/62fc55e1-74b0-4791-9c49-4bbb93a41f89" />

## 📝 License

This project is for educational purposes as part of Cloud Native Applications Lab 2.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements!

