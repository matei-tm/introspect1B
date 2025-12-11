#!/bin/bash

# EKS Dapr Microservices Setup Script
# This script sets up the complete environment for the demo
# Usage: ./setup.sh [--unattended]

set -e

echo "🚀 Starting EKS + Dapr Microservices Setup"
echo "=========================================="

# Check for unattended mode
UNATTENDED=false
if [ "$1" = "--unattended" ]; then
    UNATTENDED=true
    echo "🤖 Running in unattended mode (auto-yes to all prompts)"
fi

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

# Grant EKS admin access to current user
echo -e "\n${YELLOW}🔐 Granting EKS admin access...${NC}"
./scripts/grant-eks-admin-access.sh

# Grant EC2 instance type permissions
echo -e "\n${YELLOW}🔐 Granting EC2 instance permissions...${NC}"
./scripts/grant-ec2-permissions.sh

# Create/verify IAM roles
echo -e "\n${YELLOW}🔐 Creating/verifying IAM roles...${NC}"
./scripts/create-iam-roles.sh

# Get role ARNs
EKS_CLUSTER_ROLE_ARN=$(aws iam get-role --role-name EKSClusterRole --query 'Role.Arn' --output text)
EKS_NODE_ROLE_ARN=$(aws iam get-role --role-name EKSNodeRole --query 'Role.Arn' --output text)

echo -e "${GREEN}✅ IAM roles ready${NC}"

# Create VPC
echo -e "\n${YELLOW}🌐 Creating VPC for EKS...${NC}"
./scripts/create-vpc.sh

# Load VPC information
source /tmp/vpc-info.txt
echo -e "${GREEN}✅ VPC ready${NC}"

# Create EKS cluster if needed
if [ "$UNATTENDED" = true ]; then
    create_cluster="y"
    echo "Do you want to create a new EKS cluster? (y/n): y [auto]"
else
    read -p "Do you want to create a new EKS cluster? (y/n): " create_cluster
fi
if [ "$create_cluster" = "y" ]; then
    ./scripts/create-cluster.sh "$CLUSTER_NAME" "$AWS_REGION" "$VPC_ID" "$SUBNET_1_ID" "$SUBNET_2_ID" "$EKS_CLUSTER_ROLE_ARN" "$EKS_NODE_ROLE_ARN"
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
    aws ecr create-repository --repository-name product-service --region $AWS_REGION || true
    aws ecr create-repository --repository-name order-service --region $AWS_REGION || true
    
    echo -e "${GREEN}✅ ECR repositories ready${NC}"
fi

# Login to ECR
echo -e "\n${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo -e "${GREEN}✅ Logged into ECR${NC}"

# Build and push Docker images
echo -e "\n${YELLOW}🏗️  Building Docker images...${NC}"

# Product service
cd product-service
docker build --platform linux/amd64 -t product-service:latest .
docker tag product-service:latest $ECR_REGISTRY/product-service:latest
docker push $ECR_REGISTRY/product-service:latest
cd ..

# Order service
cd order-service
docker build --platform linux/amd64 -t order-service:latest .
docker tag order-service:latest $ECR_REGISTRY/order-service:latest
docker push $ECR_REGISTRY/order-service:latest
cd ..

echo -e "${GREEN}✅ Docker images built and pushed${NC}"

# Update Kubernetes manifests with ECR registry
echo -e "\n${YELLOW}📝 Updating Kubernetes manifests...${NC}"
sed -i.bak "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/product-deployment.yaml
sed -i.bak "s|<YOUR_ECR_REGISTRY>|$ECR_REGISTRY|g" k8s/order-deployment.yaml
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
kubectl wait --for=condition=available --timeout=300s deployment/product -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/order -n $NAMESPACE

echo -e "${GREEN}✅ All deployments ready${NC}"

# Show deployment status
echo -e "\n${YELLOW}📊 Deployment Status:${NC}"
kubectl get all -n $NAMESPACE

echo -e "\n${GREEN}🎉 Setup complete!${NC}"
echo -e "\n${YELLOW}📝 Next steps:${NC}"
echo "1. View logs: kubectl logs -f deployment/product -n $NAMESPACE -c product"
echo "2. View order logs: kubectl logs -f deployment/order -n $NAMESPACE -c order"
echo "3. Check Dapr sidecars: kubectl logs -f deployment/product -n $NAMESPACE -c daprd"
echo "4. Port-forward to test: kubectl port-forward svc/product 8080:80 -n $NAMESPACE"
echo -e "\n${YELLOW}🧹 To cleanup:${NC}"
echo "./scripts/cleanup.sh"
