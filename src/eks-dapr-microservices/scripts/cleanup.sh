#!/bin/bash

# Cleanup script for EKS Dapr demo

NAMESPACE="dapr-demo"
CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "🧹 Cleaning up EKS Dapr Microservices Demo"
echo "=========================================="

# Check if cluster is accessible
if kubectl cluster-info &>/dev/null; then
    echo "✅ Cluster is accessible, cleaning up Kubernetes resources..."
    
    # Delete Kubernetes resources
    echo "🗑️  Deleting Kubernetes resources..."
    kubectl delete -f k8s/ --ignore-not-found=true 2>/dev/null || echo "⚠️  Some resources could not be deleted (may already be gone)"
    kubectl delete -f dapr/ --ignore-not-found=true 2>/dev/null || echo "⚠️  Some Dapr components could not be deleted (may already be gone)"

    # Uninstall Redis
    echo "🗑️  Uninstalling Redis..."
    helm uninstall redis -n $NAMESPACE 2>/dev/null || echo "⚠️  Redis not found or already uninstalled"

    # Delete namespace
    echo "🗑️  Deleting namespace..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>/dev/null || true

    # Optionally delete Dapr
    read -p "Do you want to uninstall Dapr? (y/n): " uninstall_dapr
    if [ "$uninstall_dapr" = "y" ]; then
        echo "🗑️  Uninstalling Dapr..."
        helm uninstall dapr -n dapr-system 2>/dev/null || echo "⚠️  Dapr not found or already uninstalled"
        kubectl delete namespace dapr-system --ignore-not-found=true 2>/dev/null || true
    fi
else
    echo "⚠️  Cluster is not accessible. Skipping Kubernetes resource cleanup."
    echo "    (This is normal if the cluster has already been deleted)"

    # here check if the 
fi

# Optionally delete EKS cluster
read -p "Do you want to delete the EKS cluster? (y/n): " delete_cluster
if [ "$delete_cluster" = "y" ]; then
    echo "🗑️  Deleting EKS cluster..."
    eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION
    
    # Wait for cluster deletion to complete
    echo ""
    echo "⏳ Waiting for cluster deletion to complete..."
    echo "   (This may take 10-15 minutes)"
    
    while true; do
        # Check if cluster still exists
        if eksctl get cluster --name $CLUSTER_NAME --region $AWS_REGION &>/dev/null; then
            echo "⏳ Cluster still deleting... (checking again in 30 seconds)"
            sleep 30
        else
            echo "✅ Cluster successfully deleted!"
            break
        fi
    done
fi

echo "✅ Cleanup complete!"
