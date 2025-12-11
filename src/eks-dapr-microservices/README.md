# EKS Dapr Microservices Demo

A complete demonstration of containerized microservices deployed on Amazon EKS with Dapr sidecars implementing pub/sub messaging patterns for real-time event-driven interactions.

## 📋 Overview

This project demonstrates:
- **Amazon EKS**: Managed Kubernetes cluster for container orchestration
- **Dapr**: Distributed Application Runtime for microservices
- **Pub/Sub Messaging**: Event-driven communication between services
- **Redis**: Message broker for Dapr pub/sub component
- **Real-time Observability**: Live monitoring of message flows

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Amazon EKS Cluster                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Namespace: dapr-demo                       │ │
│  │                                                          │ │
│  │  ┌──────────────────┐         ┌──────────────────┐    │ │
│  │  │   Publisher Pod  │         │  Subscriber Pod  │    │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐  │    │ │
│  │  │  │ Publisher  │  │         │  │ Subscriber │  │    │ │
│  │  │  │  Service   │  │         │  │  Service   │  │    │ │
│  │  │  │ (Node.js)  │  │         │  │ (Node.js)  │  │    │ │
│  │  │  └────────────┘  │         │  └────────────┘  │    │ │
│  │  │        ↓         │         │        ↑         │    │ │
│  │  │  ┌────────────┐  │         │  ┌────────────┐  │    │ │
│  │  │  │   Dapr     │  │         │  │   Dapr     │  │    │ │
│  │  │  │  Sidecar   │◄─┼────────►│  │  Sidecar   │  │    │ │
│  │  │  └────────────┘  │         │  └────────────┘  │    │ │
│  │  └──────────────────┘         └──────────────────┘    │ │
│  │            │                            ▲              │ │
│  │            │      ┌──────────────┐     │              │ │
│  │            └─────►│    Redis     │─────┘              │ │
│  │                   │  (Pub/Sub)   │                    │ │
│  │                   └──────────────┘                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Key Features

### Publisher Service
- Automatically publishes order messages every 5 seconds
- Uses Dapr HTTP API to publish to Redis pub/sub
- Generates realistic order data (order ID, customer, product, etc.)
- Health check endpoint for Kubernetes probes

### Subscriber Service
- Subscribes to order messages via Dapr pub/sub
- Implements Dapr subscription endpoint (`/dapr/subscribe`)
- Processes incoming orders with simulated business logic
- Tracks and displays received messages
- Supports multiple replicas for load distribution

## 📦 Project Structure

```
eks-dapr-microservices/
├── publisher-service/
│   ├── app.js              # Publisher application
│   ├── package.json        # Dependencies
│   ├── Dockerfile          # Container image
│   └── .dockerignore
├── subscriber-service/
│   ├── app.js              # Subscriber application
│   ├── package.json        # Dependencies
│   ├── Dockerfile          # Container image
│   └── .dockerignore
├── k8s/
│   ├── namespace.yaml               # Kubernetes namespace
│   ├── publisher-deployment.yaml    # Publisher deployment
│   ├── publisher-service.yaml       # Publisher service
│   ├── subscriber-deployment.yaml   # Subscriber deployment (2 replicas)
│   └── subscriber-service.yaml      # Subscriber service
├── dapr/
│   ├── pubsub.yaml         # Dapr pub/sub component (Redis)
│   ├── statestore.yaml     # Dapr state store component
│   └── configuration.yaml  # Dapr configuration
├── scripts/
│   ├── setup.sh            # Complete setup automation
│   ├── cleanup.sh          # Cleanup resources
│   └── test.sh             # Test and verify deployment
└── README.md
```

## 🚀 Prerequisites

Before starting, ensure you have:

- **AWS CLI** (v2.x): [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **kubectl** (v1.27+): [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **eksctl** (v0.147+): [Installation Guide](https://eksctl.io/installation/)
- **Helm** (v3.x): [Installation Guide](https://helm.sh/docs/intro/install/)
- **Docker**: [Installation Guide](https://docs.docker.com/get-docker/)
- **AWS Account** with appropriate permissions
- **AWS credentials** configured (`aws configure`)

## 📥 Installation

### Option 1: Automated Setup (Recommended)

```bash
cd src/eks-dapr-microservices
./scripts/setup.sh
```

The script will:
1. ✅ Check prerequisites
2. 🏗️ Create EKS cluster (optional)
3. ⚙️ Configure kubectl
4. 📦 Install Dapr on Kubernetes
5. 📦 Install Redis for pub/sub
6. 🐳 Build and push Docker images to ECR
7. 🚀 Deploy microservices to EKS
8. ⏳ Wait for deployments to be ready

### Option 2: Manual Setup

#### Step 1: Create EKS Cluster

```bash
eksctl create cluster \
  --name dapr-demo-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.micro \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 4 \
  --managed
```

#### Step 2: Install Dapr

```bash
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade --install dapr dapr/dapr \
  --version=1.12 \
  --namespace dapr-system \
  --create-namespace \
  --wait
```

#### Step 3: Install Redis

```bash
kubectl create namespace dapr-demo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install redis bitnami/redis \
  --namespace dapr-demo \
  --set auth.password=redis123 \
  --set master.persistence.enabled=false \
  --set replica.replicaCount=1
```

#### Step 4: Build and Push Docker Images

```bash
# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-1
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Create ECR repositories
aws ecr create-repository --repository-name publisher-service --region $AWS_REGION
aws ecr create-repository --repository-name subscriber-service --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push publisher
cd publisher-service
docker build -t publisher-service:latest .
docker tag publisher-service:latest $ECR_REGISTRY/publisher-service:latest
docker push $ECR_REGISTRY/publisher-service:latest
cd ..

# Build and push subscriber
cd subscriber-service
docker build -t subscriber-service:latest .
docker tag subscriber-service:latest $ECR_REGISTRY/subscriber-service:latest
docker push $ECR_REGISTRY/subscriber-service:latest
cd ..
```

#### Step 5: Update Kubernetes Manifests

Update `<YOUR_ECR_REGISTRY>` in the deployment files with your ECR registry URL:

```bash
sed -i "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/publisher-deployment.yaml
sed -i "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/subscriber-deployment.yaml
```

#### Step 6: Deploy to Kubernetes

```bash
# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Apply Dapr components
kubectl apply -f dapr/

# Apply applications
kubectl apply -f k8s/
```

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
NAME                          READY   STATUS    RESTARTS   AGE
publisher-xxxxxxxxxx-xxxxx    2/2     Running   0          2m
subscriber-xxxxxxxxxx-xxxxx   2/2     Running   0          2m
subscriber-xxxxxxxxxx-yyyyy   2/2     Running   0          2m
redis-master-0                1/1     Running   0          3m
```

#### 2. View Publisher Logs

```bash
kubectl logs -f deployment/publisher -n dapr-demo -c publisher
```

You should see:
```
🚀 Publisher service listening on port 3000
📡 Dapr sidecar expected on port 3500
📢 Publishing to topic: orders
✅ Published order: order-1702234567890-1 { orderId: '...', ... }
```

#### 3. View Subscriber Logs

```bash
kubectl logs -f deployment/subscriber -n dapr-demo -c subscriber
```

You should see:
```
🚀 Subscriber service listening on port 3001
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

### Manual Cleanup

```bash
# Delete applications
kubectl delete -f k8s/
kubectl delete -f dapr/

# Uninstall Redis
helm uninstall redis -n dapr-demo

# Delete namespace
kubectl delete namespace dapr-demo

# Optionally uninstall Dapr
helm uninstall dapr -n dapr-system
kubectl delete namespace dapr-system

# Optionally delete EKS cluster
eksctl delete cluster --name dapr-demo-cluster --region us-east-1
```

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
- Publisher and subscriber services containerized with Docker
- Deployed to managed EKS cluster

✅ **Implement Dapr sidecars**
- Dapr sidecar injected into each pod via annotations
- Handles all pub/sub communication

✅ **Pub/Sub messaging pattern**
- Redis-backed pub/sub component
- Real-time event publishing and subscription

✅ **Observe real-time interactions**
- Live log streaming shows message flow
- Multiple subscriber replicas demonstrate load distribution
- Health endpoints provide status visibility

## 📝 License

This project is for educational purposes as part of Cloud Native Applications Lab 2.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements!
