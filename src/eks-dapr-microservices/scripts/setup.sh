#!/bin/bash

# EKS Dapr Microservices Setup Script
# This script sets up the complete environment for the demo

set -e

echo "🚀 Starting EKS + Dapr Microservices Setup"
echo "=========================================="

# Variables
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo-cluster}"
ECR_REGISTRY="${ECR_REGISTRY:-}"
NAMESPACE="dapr-demo"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${YELLOW}📋 Checking prerequisites...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}❌ Helm is required but not installed.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✅ All prerequisites found${NC}"

# Create/verify IAM roles
echo -e "\n${YELLOW}🔐 Creating/verifying IAM roles...${NC}"
./scripts/create-iam-roles.sh

# Get role ARNs
EKS_CLUSTER_ROLE_ARN=$(aws iam get-role --role-name EKSClusterRole --query 'Role.Arn' --output text)
EKS_NODE_ROLE_ARN=$(aws iam get-role --role-name EKSNodeRole --query 'Role.Arn' --output text)

echo -e "${GREEN}✅ IAM roles ready${NC}"

# Create EKS cluster if needed
read -p "Do you want to create a new EKS cluster? (y/n): " create_cluster
if [ "$create_cluster" = "y" ]; then
    echo -e "\n${YELLOW}🏗️  Creating EKS cluster...${NC}"
    
    # Create cluster configuration file
    cat > /tmp/cluster-config.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $CLUSTER_NAME
  region: $AWS_REGION

autoModeConfig:
  enabled: false

iam:
  serviceRoleARN: $EKS_CLUSTER_ROLE_ARN
  withOIDC: true

managedNodeGroups:
  - name: standard-workers
    instanceType: t2.micro
    minSize: 1
    maxSize: 3
    desiredCapacity: 2
    iam:
      instanceRoleARN: $EKS_NODE_ROLE_ARN
EOF
    
    eksctl create cluster -f /tmp/cluster-config.yaml
    
    rm -f /tmp/cluster-config.yaml
    echo -e "${GREEN}✅ EKS cluster created${NC}"
fi

# Configure kubectl
echo -e "\n${YELLOW}⚙️  Configuring kubectl...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
echo -e "${GREEN}✅ kubectl configured${NC}"

# Install Dapr on Kubernetes
echo -e "\n${YELLOW}📦 Installing Dapr on Kubernetes...${NC}"
helm repo add dapr https://dapr.github.io/helm-charts/ || true
helm repo update
helm upgrade --install dapr dapr/dapr \
    --version=1.12 \
    --namespace dapr-system \
    --create-namespace \
    --wait

echo -e "${GREEN}✅ Dapr installed${NC}"

# Verify Dapr installation
echo -e "\n${YELLOW}🔍 Verifying Dapr installation...${NC}"
kubectl get pods --namespace dapr-system
kubectl wait --for=condition=ready pod --all -n dapr-system --timeout=300s

# Install Redis using Helm
echo -e "\n${YELLOW}📦 Installing Redis for pub/sub...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update
helm upgrade --install redis bitnami/redis \
    --namespace $NAMESPACE \
    --set auth.password=redis123 \
    --set master.persistence.enabled=false \
    --set replica.replicaCount=1 \
    --wait

echo -e "${GREEN}✅ Redis installed${NC}"

# Get or create ECR registry
if [ -z "$ECR_REGISTRY" ]; then
    echo -e "\n${YELLOW}🐳 Setting up ECR repositories...${NC}"
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Create ECR repositories
    aws ecr create-repository --repository-name publisher-service --region $AWS_REGION || true
    aws ecr create-repository --repository-name subscriber-service --region $AWS_REGION || true
    
    echo -e "${GREEN}✅ ECR repositories ready${NC}"
fi

# Login to ECR
echo -e "\n${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo -e "${GREEN}✅ Logged into ECR${NC}"

# Build and push Docker images
echo -e "\n${YELLOW}🏗️  Building Docker images...${NC}"

# Publisher service
cd publisher-service
docker build -t publisher-service:latest .
docker tag publisher-service:latest $ECR_REGISTRY/publisher-service:latest
docker push $ECR_REGISTRY/publisher-service:latest
cd ..

# Subscriber service
cd subscriber-service
docker build -t subscriber-service:latest .
docker tag subscriber-service:latest $ECR_REGISTRY/subscriber-service:latest
docker push $ECR_REGISTRY/subscriber-service:latest
cd ..

echo -e "${GREEN}✅ Docker images built and pushed${NC}"

# Update Kubernetes manifests with ECR registry
echo -e "\n${YELLOW}📝 Updating Kubernetes manifests...${NC}"
sed -i.bak "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/publisher-deployment.yaml
sed -i.bak "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/subscriber-deployment.yaml
rm -f k8s/*.bak

# Deploy to Kubernetes
echo -e "\n${YELLOW}🚀 Deploying to Kubernetes...${NC}"

# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Apply Dapr components
kubectl apply -f dapr/

# Apply services and deployments
kubectl apply -f k8s/

echo -e "${GREEN}✅ Applications deployed${NC}"

# Wait for deployments
echo -e "\n${YELLOW}⏳ Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/publisher -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/subscriber -n $NAMESPACE

echo -e "${GREEN}✅ All deployments ready${NC}"

# Show deployment status
echo -e "\n${YELLOW}📊 Deployment Status:${NC}"
kubectl get all -n $NAMESPACE

echo -e "\n${GREEN}🎉 Setup complete!${NC}"
echo -e "\n${YELLOW}📝 Next steps:${NC}"
echo "1. View logs: kubectl logs -f deployment/publisher -n $NAMESPACE -c publisher"
echo "2. View subscriber logs: kubectl logs -f deployment/subscriber -n $NAMESPACE -c subscriber"
echo "3. Check Dapr sidecars: kubectl logs -f deployment/publisher -n $NAMESPACE -c daprd"
echo "4. Port-forward to test: kubectl port-forward svc/publisher 8080:80 -n $NAMESPACE"
echo -e "\n${YELLOW}🧹 To cleanup:${NC}"
echo "./scripts/cleanup.sh"
