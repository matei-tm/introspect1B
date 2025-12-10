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

# Optionally delete VPC
read -p "Do you want to delete the VPC? (y/n): " delete_vpc
if [ "$delete_vpc" = "y" ]; then
    echo "🗑️  Deleting VPC resources..."
    
    # Load VPC information if available
    if [ -f /tmp/vpc-info.txt ]; then
        source /tmp/vpc-info.txt
        
        # Delete subnets
        if [ -n "$SUBNET_1_ID" ]; then
            echo "🗑️  Deleting Subnet 1..."
            aws ec2 delete-subnet --subnet-id $SUBNET_1_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  Subnet 1 not found or already deleted"
        fi
        
        if [ -n "$SUBNET_2_ID" ]; then
            echo "🗑️  Deleting Subnet 2..."
            aws ec2 delete-subnet --subnet-id $SUBNET_2_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  Subnet 2 not found or already deleted"
        fi
        
        # Delete route table (custom ones, not main)
        if [ -n "$ROUTE_TABLE_ID" ]; then
            echo "🗑️  Deleting Route Table..."
            aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  Route table not found or already deleted"
        fi
        
        # Detach and delete Internet Gateway
        if [ -n "$IGW_ID" ] && [ -n "$VPC_ID" ]; then
            echo "🗑️  Detaching Internet Gateway..."
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  IGW already detached"
            
            echo "🗑️  Deleting Internet Gateway..."
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  IGW not found or already deleted"
        fi
        
        # Delete VPC
        if [ -n "$VPC_ID" ]; then
            echo "🗑️  Deleting VPC..."
            aws ec2 delete-vpc --vpc-id $VPC_ID --region $AWS_REGION 2>/dev/null || echo "⚠️  VPC not found or already deleted"
            echo "✅ VPC deleted!"
        fi
        
        # Clean up temp file
        rm -f /tmp/vpc-info.txt
    else
        echo "⚠️  VPC information file not found. Cannot auto-delete VPC resources."
        echo "    Please manually delete VPC resources from AWS Console if needed."
    fi
fi

echo "✅ Cleanup complete!"
