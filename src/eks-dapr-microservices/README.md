# EKS Dapr Microservices Demo

A complete demonstration of containerized microservices deployed on Amazon EKS with Dapr sidecars implementing pub/sub messaging patterns using AWS SNS/SQS for real-time event-driven interactions.

## 📋 Overview

This project demonstrates:
- **Amazon EKS**: Managed Kubernetes cluster for container orchestration
- **Dapr**: Distributed Application Runtime for microservices
- **Pub/Sub Messaging**: Event-driven communication between services using AWS SNS/SQS
- **AWS SNS/SQS**: Native AWS messaging services for pub/sub
- **AWS DynamoDB**: State store for Dapr
- **IRSA**: IAM Roles for Service Accounts for secure AWS access
- **Real-time Observability**: Live monitoring of message flows

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Amazon EKS Cluster                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Namespace: dapr-demo                           │ │
│  │                                                              │ │
│  │  ┌──────────────────┐         ┌──────────────────┐        │ │
│  │  │  Product Pod     │         │   Order Pod      │        │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐  │        │ │
│  │  │  │  Product   │  │         │  │   Order    │  │        │ │
│  │  │  │  Service   │  │         │  │  Service   │  │        │ │
│  │  │  │ (Node.js)  │  │         │  │ (Node.js)  │  │        │ │
│  │  │  └────────────┘  │         │  └────────────┘  │        │ │
│  │  │        ↓         │         │        ↑         │        │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐  │        │ │
│  │  │  │   Dapr     │  │         │  │   Dapr     │  │        │ │
│  │  │  │  Sidecar   │  │         │  │  Sidecar   │  │        │ │
│  │  │  └─────┬──────┘  │         │  └──────┬─────┘  │        │ │
│  │  └────────┼─────────┘         └─────────┼────────┘        │ │
│  │            │                             │                 │ │
│  │            │   (IRSA Authentication)     │                 │ │
│  └────────────┼─────────────────────────────┼─────────────────┘ │
│               │                             │                   │
│               ↓                             ↓                   │
└───────────────┼─────────────────────────────┼───────────────────┘
                │                             │
         ┌──────▼──────┐             ┌───────▼────────┐
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

## 📦 Project Structure

```
eks-dapr-microservices/
├── product-service/
│   ├── app.js              # Product service application
│   ├── package.json        # Dependencies
│   ├── Dockerfile          # Container image
│   └── .dockerignore
├── order-service/
│   ├── app.js              # Order service application
│   ├── package.json        # Dependencies
│   ├── Dockerfile          # Container image
│   └── .dockerignore
├── terraform/
│   ├── main.tf             # Main Terraform configuration
│   ├── vpc.tf              # VPC and networking
│   ├── eks.tf              # EKS cluster configuration
│   ├── iam.tf              # IAM roles and policies (including IRSA)
│   ├── ecr.tf              # ECR repositories
│   ├── aws-resources.tf    # SNS, SQS, DynamoDB
│   ├── kubernetes.tf       # Kubernetes resources
│   ├── helm.tf             # Dapr and Metrics Server
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── terraform.tfvars.example
├── k8s/
│   ├── dapr-rbac.yaml           # RBAC for Dapr component access
│   ├── product-deployment.yaml  # Product deployment with manual sidecar
│   ├── product-service.yaml     # Product service
│   ├── order-deployment.yaml    # Order deployment (2 replicas)
│   └── order-service.yaml       # Order service
├── dapr/
│   ├── pubsub.yaml         # Dapr pub/sub component (AWS SNS/SQS)
│   ├── statestore.yaml     # Dapr state store (AWS DynamoDB)
│   └── configuration.yaml  # Dapr configuration
├── .github/workflows/
│   ├── terraform-deploy.yml     # Infrastructure deployment
│   └── deploy-services.yml      # Service deployment workflow
├── scripts/
│   ├── simulate-github-deploy.sh    # Local simulation of GitHub Actions
│   ├── simulate-github-start-lab.sh # Start lab verification
│   └── cleanup.sh                   # Cleanup resources
└── README.md
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

## 📥 Deployment

The project uses a two-stage deployment approach:
1. **Infrastructure**: Terraform provisions EKS, VPC, IAM, ECR, SNS/SQS, DynamoDB
2. **Services**: GitHub Actions (or local simulation) builds and deploys microservices

### Step 1: Deploy Infrastructure with Terraform

```bash
cd terraform

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

Terraform will create:
- ✅ VPC with public/private subnets
- ✅ EKS cluster (v1.31) with managed node group
- ✅ ECR repositories for product-service and order-service
- ✅ SNS topic and SQS queue for pub/sub messaging
- ✅ DynamoDB table for state store
- ✅ IAM roles with IRSA for secure AWS access
- ✅ Dapr 1.12.5 installed via Helm
- ✅ Metrics Server for resource monitoring
- ✅ Kubernetes namespace and service account

### Step 2: Deploy Services

#### Option A: Using GitHub Actions (Recommended for CI/CD)

1. Push your code to GitHub
2. Configure repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Trigger the workflow:
   - **Automatic**: Push changes to `product-service/` or `order-service/`
   - **Manual**: Run workflow via GitHub Actions UI

The workflow (`.github/workflows/deploy-services.yml`) will:
- Login to ECR
- Build Docker images for linux/amd64
- Push images to ECR
- Apply Dapr components and RBAC
- Deploy services to EKS
- Wait for rollout completion

#### Option B: Local Simulation (Recommended for Development)

```bash
cd src/eks-dapr-microservices

# Deploy all services
./scripts/simulate-github-deploy.sh all

# Or deploy individual services
./scripts/simulate-github-deploy.sh product-service
./scripts/simulate-github-deploy.sh order-service
```

The script will:
1. ✅ Verify AWS credentials
2. ✅ Login to ECR
3. ✅ Build Docker images (linux/amd64)
4. ✅ Push images to ECR
5. ✅ Update kubeconfig for EKS access
6. ✅ Apply Dapr RBAC and components
7. ✅ Create ConfigMap for component mounting
8. ✅ Deploy services and wait for readiness

## 🧪 Testing and Verification

### Quick Test

```bash
./scripts/test.sh
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

#### 2. View Product Service Logs

```bash
kubectl logs -f deployment/product -n dapr-demo -c product
```

You should see:
```
🚀 Publisher service listening on port 3000
📡 Dapr sidecar expected on port 3500
📢 Publishing to topic: orders
✅ Published order: order-1702234567890-1 { orderId: '...', ... }
```

#### 3. View Order Service Logs

```bash
kubectl logs -f deployment/order -n dapr-demo -c order
```

You should see:
```
🚀 Order service listening on port 3001
👂 Subscribed to topic: orders
📦 [1] Received order: { orderId: '...', product: 'laptop', ... }
✅ Order order-1702234567890-1 processed successfully
```

#### 4. Check Dapr Sidecars

```bash
kubectl logs deployment/product -n dapr-demo -c daprd --tail=20
```

#### 5. Verify Dapr Components

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

### Method 1: Log Streaming

Watch both services simultaneously:

```bash
# Terminal 1 - Publisher
kubectl logs -f deployment/product -n dapr-demo -c product

# Terminal 2 - Subscriber  
kubectl logs -f deployment/order -n dapr-demo -c order
```

### Method 2: Port Forwarding

Access the subscriber's messages endpoint:

```bash
kubectl port-forward svc/subscriber 8081:80 -n dapr-demo
```

Then visit: http://localhost:8081/messages

### Method 3: Manual Publishing

Test manual message publishing:

```bash
kubectl port-forward svc/publisher 8080:80 -n dapr-demo
```

```bash
curl -X POST http://localhost:8080/publish
```

## 🔧 Configuration

### Environment Variables

**Publisher Service:**
- `PORT`: HTTP server port (default: 3000)
- `DAPR_HTTP_PORT`: Dapr sidecar HTTP port (default: 3500)

**Subscriber Service:**
- `PORT`: HTTP server port (default: 3001)

### Scaling

Scale subscriber replicas:

```bash
kubectl scale deployment/subscriber -n dapr-demo --replicas=5
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

### Redis Connection Issues

```bash
kubectl get pods -n dapr-demo | grep redis
kubectl logs redis-master-0 -n dapr-demo
```

### No Messages Being Received

1. Check publisher is publishing:
   ```bash
   kubectl logs deployment/publisher -n dapr-demo -c publisher
   ```

2. Check Dapr component status:
   ```bash
   kubectl describe component messagepubsub -n dapr-demo
   ```

3. Verify Redis is running:
   ```bash
   kubectl get pods -n dapr-demo -l app.kubernetes.io/name=redis
   ```

## 🧹 Cleanup

### Quick Cleanup

```bash
./scripts/cleanup.sh
```

### Complete Infrastructure Cleanup

```bash
# Delete services first
kubectl delete -f k8s/ -n dapr-demo
kubectl delete configmap dapr-components -n dapr-demo

# Then destroy infrastructure with Terraform
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
- Application container (publisher/subscriber)
- Dapr sidecar container (handles infrastructure concerns)

### 2. Pub/Sub Messaging
- **Decoupling**: Publisher and subscriber don't know about each other
- **Scalability**: Multiple subscriber replicas can process messages
- **Reliability**: Redis ensures message delivery

### 3. Kubernetes Best Practices
- Health checks (liveness/readiness probes)
- Resource limits and requests
- Namespaces for isolation
- Services for networking
- ConfigMaps and Secrets for configuration

### 4. Event-Driven Architecture
- Asynchronous communication
- Real-time message processing
- Horizontal scalability

## 📖 Learning Resources

- [Dapr Documentation](https://docs.dapr.io/)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
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

## ✅ Verification

Check the services are working:

```bash
kubectl logs -n dapr-demo -l app=product -c product --tail=10 && echo "---ORDER SERVICE---" && kubectl logs -n dapr-demo -l app=order -c order --tail=10
```

**Expected output:**

```text
  timestamp: '2025-12-12T02:29:45.977Z'
}
✅ Published order: order-1765506590978-44 {
  orderId: 'order-1765506590978-44',
  customerId: 'customer-277',
  product: 'laptop',
  quantity: 5,
  totalAmount: '402.29',
  timestamp: '2025-12-12T02:29:50.978Z'
}
---ORDER SERVICE---

> order-service@1.0.0 start
> node app.js

🚀 Order service listening on port 3001
👂 Subscribed to topic: orders
📡 Dapr will send messages to /orders endpoint
📋 Subscription configuration requested
}
✅ Order order-1765506590978-44 processed successfully

📦 [27] Received order: {
  orderId: 'order-1765506595980-45',
  product: 'phone',
  quantity: 1,
  amount: '162.09',
  timestamp: '2025-12-12T02:29:55.980Z'
}
```

This shows:
- ✅ **Product service** publishing messages to AWS SNS
- ✅ **Order service** receiving messages from AWS SQS
- ✅ **End-to-end flow** working through AWS native services


## 📝 License

This project is for educational purposes as part of Cloud Native Applications Lab 2.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements!
