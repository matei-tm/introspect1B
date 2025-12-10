#!/bin/bash

# Cleanup script for EKS Dapr demo

set -e

NAMESPACE="dapr-demo"
CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "🧹 Cleaning up EKS Dapr Microservices Demo"
echo "=========================================="

# Delete Kubernetes resources
echo "🗑️  Deleting Kubernetes resources..."
kubectl delete -f k8s/ --ignore-not-found=true
kubectl delete -f dapr/ --ignore-not-found=true

# Uninstall Redis
echo "🗑️  Uninstalling Redis..."
helm uninstall redis -n $NAMESPACE || true

# Delete namespace
echo "🗑️  Deleting namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

# Optionally delete Dapr
read -p "Do you want to uninstall Dapr? (y/n): " uninstall_dapr
if [ "$uninstall_dapr" = "y" ]; then
    echo "🗑️  Uninstalling Dapr..."
    helm uninstall dapr -n dapr-system || true
    kubectl delete namespace dapr-system --ignore-not-found=true
fi

# Optionally delete EKS cluster
read -p "Do you want to delete the EKS cluster? (y/n): " delete_cluster
if [ "$delete_cluster" = "y" ]; then
    echo "🗑️  Deleting EKS cluster..."
    eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION
fi

echo "✅ Cleanup complete!"
