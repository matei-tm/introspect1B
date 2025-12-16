#!/bin/bash

# Cleanup script for EKS Dapr demo
# Usage: ./cleanup.sh [--unattended]

NAMESPACE="dapr-demo"
CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Check for unattended mode
UNATTENDED=false
if [ "$1" = "--unattended" ]; then
    UNATTENDED=true
    echo "🤖 Running in unattended mode (auto-yes to all prompts)"
fi

echo "🧹 Cleaning up EKS Dapr Microservices Demo"
echo "=========================================="

# Check if cluster is accessible
if kubectl cluster-info &>/dev/null; then
    echo "✅ Cluster is accessible, cleaning up Kubernetes resources..."
    
    # Delete Kubernetes resources
    echo "🗑️  Deleting Kubernetes resources..."
    kubectl delete -f k8s/ --ignore-not-found=true 2>/dev/null || echo "⚠️  Some resources could not be deleted (may already be gone)"
    kubectl delete -f dapr/ --ignore-not-found=true 2>/dev/null || echo "⚠️  Some Dapr components could not be deleted (may already be gone)"

    # Delete CloudWatch namespace and resources
    echo "🗑️  Deleting CloudWatch Container Insights..."
    kubectl delete namespace amazon-cloudwatch --ignore-not-found=true 2>/dev/null || true

    # Delete namespace
    echo "🗑️  Deleting namespace $NAMESPACE..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>/dev/null || true

    # Optionally delete Dapr
    if [ "$UNATTENDED" = true ]; then
        uninstall_dapr="y"
        echo "Do you want to uninstall Dapr? (y/n): y [auto]"
    else
        read -p "Do you want to uninstall Dapr? (y/n): " uninstall_dapr
    fi
    if [ "$uninstall_dapr" = "y" ]; then
        echo "🗑️  Uninstalling Dapr..."
        helm uninstall dapr -n dapr-system 2>/dev/null || echo "⚠️  Dapr not found or already uninstalled"
        kubectl delete namespace dapr-system --ignore-not-found=true 2>/dev/null || true
    fi
else
    echo "⚠️  Cluster is not accessible. Skipping Kubernetes resource cleanup."
    echo "    (This is normal if the cluster has already been deleted)"
fi

# Optionally delete AWS resources (SNS, SQS, DynamoDB, ECR)
if [ "$UNATTENDED" = true ]; then
    delete_aws_resources="y"
    echo "Do you want to delete AWS resources (SNS, SQS, DynamoDB, ECR, CloudWatch)? (y/n): y [auto]"
else
    read -p "Do you want to delete AWS resources (SNS, SQS, DynamoDB, ECR, CloudWatch)? (y/n): " delete_aws_resources
fi
if [ "$delete_aws_resources" = "y" ]; then
    echo "🗑️  Deleting AWS resources..."
    
    # Delete ECR repositories
    echo "🗑️  Deleting ECR repositories..."
    for service in product-service order-service; do
        aws ecr delete-repository --repository-name $service --region $AWS_REGION --force 2>/dev/null || echo "⚠️  ECR repository $service not found or already deleted"
    done
    
    # Delete SNS subscription
    echo "🗑️  Deleting SNS subscription..."
    SUBSCRIPTION_ARN=$(aws sns list-subscriptions --region $AWS_REGION --query "Subscriptions[?TopicArn=='arn:aws:sns:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):orders'].SubscriptionArn" --output text 2>/dev/null)
    if [ -n "$SUBSCRIPTION_ARN" ]; then
        aws sns unsubscribe --subscription-arn $SUBSCRIPTION_ARN --region $AWS_REGION 2>/dev/null || echo "⚠️  Failed to delete SNS subscription"
    fi
    
    # Delete SQS queue
    echo "🗑️  Deleting SQS queue..."
    aws sqs delete-queue --queue-url "https://sqs.${AWS_REGION}.amazonaws.com/$(aws sts get-caller-identity --query Account --output text)/order" --region $AWS_REGION 2>/dev/null || echo "⚠️  SQS queue not found or already deleted"
    
    # Delete SNS topic
    echo "🗑️  Deleting SNS topic..."
    aws sns delete-topic --topic-arn "arn:aws:sns:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):orders" --region $AWS_REGION 2>/dev/null || echo "⚠️  SNS topic not found or already deleted"
    
    # Delete DynamoDB table
    echo "🗑️  Deleting DynamoDB table..."
    aws dynamodb delete-table --table-name dapr-state --region $AWS_REGION 2>/dev/null || echo "⚠️  DynamoDB table not found or already deleted"
    
    # Delete CloudWatch log groups
    echo "🗑️  Deleting CloudWatch log groups..."
    aws logs delete-log-group --log-group-name "/aws/containerinsights/${CLUSTER_NAME}/application" --region $AWS_REGION 2>/dev/null || echo "⚠️  Application log group not found or already deleted"
    aws logs delete-log-group --log-group-name "/aws/containerinsights/${CLUSTER_NAME}/performance" --region $AWS_REGION 2>/dev/null || echo "⚠️  Performance log group not found or already deleted"
    
    echo "✅ AWS resources cleanup complete!"
fi

# Optionally delete EKS cluster
if [ "$UNATTENDED" = true ]; then
    delete_cluster="y"
    echo "Do you want to delete the EKS cluster? (y/n): y [auto]"
else
    read -p "Do you want to delete the EKS cluster? (y/n): " delete_cluster
fi
if [ "$delete_cluster" = "y" ]; then
    echo "🗑️  Deleting EKS cluster and node groups..."
    
    # First, delete all node groups
    echo "🗑️  Listing and deleting node groups..."
    NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $AWS_REGION --query 'nodegroups[*]' --output text 2>/dev/null)
    
    if [ -n "$NODEGROUPS" ]; then
        for ng in $NODEGROUPS; do
            echo "🗑️  Deleting node group: $ng"
            aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $ng --region $AWS_REGION 2>/dev/null || echo "⚠️  Failed to delete node group $ng"
        done
        
        # Wait for all node groups to be deleted
        echo "⏳ Waiting for node groups to be deleted..."
        echo "   (This may take 5-10 minutes)"
        while true; do
            REMAINING=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $AWS_REGION --query 'nodegroups[*]' --output text 2>/dev/null)
            if [ -z "$REMAINING" ]; then
                echo "✅ All node groups deleted!"
                break
            fi
            echo "⏳ Node groups still deleting... (checking again in 30 seconds)"
            sleep 30
        done
    else
        echo "ℹ️  No node groups found or cluster doesn't exist"
    fi
    
    # Now delete the cluster
    echo "🗑️  Deleting EKS cluster $CLUSTER_NAME..."
    eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION
    
    # Wait for cluster deletion to complete
    echo ""
    echo "⏳ Waiting for cluster deletion to complete..."
    echo "   (This may take 5-10 minutes)"
    
    while true; do
        # Check if cluster still exists
        if eksctl get cluster --name $CLUSTER_NAME --region $AWS_REGION &>/dev/null; then
            echo "⏳ Cluster $CLUSTER_NAME still deleting... (checking again in 30 seconds)"
            sleep 30
        else
            echo "✅ Cluster $CLUSTER_NAME successfully deleted!"
            break
        fi
    done
fi

# Note: VPC, subnets, and other networking resources are managed by Terraform
# Use 'cd terraform && terraform destroy' to clean up all Terraform-managed resources

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📝 Next steps:"
echo "   - To destroy all Terraform-managed infrastructure, run:"
echo "     cd terraform && terraform destroy"
echo ""
echo "   - To verify all resources are deleted:"
echo "     aws eks list-clusters --region $AWS_REGION"
echo "     aws ecr describe-repositories --region $AWS_REGION"
echo "     aws sns list-topics --region $AWS_REGION"
echo "     aws sqs list-queues --region $AWS_REGION"
echo "     aws dynamodb list-tables --region $AWS_REGION"
