#!/bin/bash
# Simulate GitHub Actions deployment workflow locally
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Environment variables
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=dapr-demo-cluster
export ECR_REGISTRY=${ECR_REGISTRY:-322230759107.dkr.ecr.us-east-1.amazonaws.com}
export NAMESPACE=dapr-demo
export GITHUB_SHA=$(git rev-parse HEAD)

# Parse arguments
SERVICE="${1:-all}"

echo -e "${BLUE}======================================"
echo "Simulating GitHub Actions Workflow"
echo "Service: $SERVICE"
echo "======================================${NC}"

# Check AWS credentials
echo -e "${YELLOW}Verifying AWS credentials...${NC}"
aws sts get-caller-identity || { echo "AWS credentials not configured"; exit 1; }

# Login to ECR
echo -e "${YELLOW}Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Get to the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Function to build and push service
build_and_push() {
  local service_name=$1
  local service_dir=$2
  
  echo -e "${BLUE}======================================"
  echo "Building $service_name..."
  echo "======================================${NC}"
  
  cd "$service_dir"
  export ECR_REPOSITORY=$service_name
  export IMAGE_TAG=$GITHUB_SHA
  
  echo "Building Docker image for linux/amd64..."
  docker build --platform linux/amd64 -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
  docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
  
  echo "Pushing to ECR..."
  docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
  docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
  
  echo -e "${GREEN}✅ $service_name image pushed: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG${NC}"
  cd "$PROJECT_DIR"
}

# Function to deploy service
deploy_service() {
  local service_name=$1
  local deployment_file=$2
  local service_file=$3
  
  echo -e "${BLUE}======================================"
  echo "Deploying $service_name..."
  echo "======================================${NC}"
  
  kubectl apply -f "k8s/$service_file" -n $NAMESPACE
  
  # Apply deployment with environment variable substitution
  envsubst < "k8s/$deployment_file" | kubectl apply -f - -n $NAMESPACE
  
  echo "Waiting for $service_name rollout..."
  kubectl rollout status deployment/$service_name -n $NAMESPACE --timeout=5m
  
  echo -e "${GREEN}✅ $service_name deployed successfully${NC}"
  
  echo "Checking $service_name pods..."
  kubectl get pods -n $NAMESPACE -l app=$service_name
}

# Update kubeconfig
echo -e "${YELLOW}Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
kubectl cluster-info

# Deploy Dapr components
echo -e "${BLUE}======================================"
echo "Deploying Dapr components..."
echo "======================================${NC}"

# Apply RBAC for Dapr component access
echo -e "${YELLOW}Applying Dapr RBAC...${NC}"
kubectl apply -f k8s/dapr-rbac.yaml || echo "RBAC already exists"

# Apply Dapr components (CRDs)
kubectl apply -f dapr/ -n $NAMESPACE || echo "Dapr components already exist"

# Create Dapr components ConfigMap for sidecar mounting
echo -e "${YELLOW}Creating Dapr components ConfigMap...${NC}"
kubectl create configmap dapr-components \
  --from-file=dapr/pubsub.yaml \
  --from-file=dapr/statestore.yaml \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Dapr components configured${NC}"

# Build and deploy based on service argument
if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "product-service" ]]; then
  build_and_push "product-service" "$PROJECT_DIR/product-service"
  deploy_service "product" "product-deployment.yaml" "product-service.yaml"
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "order-service" ]]; then
  build_and_push "order-service" "$PROJECT_DIR/order-service"
  deploy_service "order" "order-deployment.yaml" "order-service.yaml"
fi

# Summary
echo -e "${BLUE}======================================"
echo "🚀 Deployment Summary"
echo "======================================${NC}"

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "product-service" ]]; then
  echo -e "${GREEN}✅ Product Service: Deployed successfully${NC}"
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "order-service" ]]; then
  echo -e "${GREEN}✅ Order Service: Deployed successfully${NC}"
fi

echo ""
echo "Deployment Details:"
echo "- Cluster: $EKS_CLUSTER_NAME"
echo "- Region: $AWS_REGION"
echo "- Namespace: $NAMESPACE"
echo "- Commit: $GITHUB_SHA"
echo ""
echo "All pods in $NAMESPACE:"
kubectl get pods -n $NAMESPACE
