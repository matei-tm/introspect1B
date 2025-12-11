#!/bin/bash

# Create EKS Cluster Script
# Usage: ./create-cluster.sh <cluster-name> <region> <vpc-id> <subnet1-id> <subnet2-id> <cluster-role-arn> <node-role-arn>

set -e

# Arguments
CLUSTER_NAME=$1
AWS_REGION=$2
VPC_ID=$3
SUBNET_1_ID=$4
SUBNET_2_ID=$5
EKS_CLUSTER_ROLE_ARN=$6
EKS_NODE_ROLE_ARN=$7

# Validate arguments
if [ -z "$CLUSTER_NAME" ] || [ -z "$AWS_REGION" ] || [ -z "$VPC_ID" ] || [ -z "$SUBNET_1_ID" ] || [ -z "$SUBNET_2_ID" ] || [ -z "$EKS_CLUSTER_ROLE_ARN" ] || [ -z "$EKS_NODE_ROLE_ARN" ]; then
    echo "Usage: $0 <cluster-name> <region> <vpc-id> <subnet1-id> <subnet2-id> <cluster-role-arn> <node-role-arn>"
    exit 1
fi

# Export variables for envsubst
export CLUSTER_NAME
export AWS_REGION
export VPC_ID
export SUBNET_1_ID
export SUBNET_2_ID
export EKS_CLUSTER_ROLE_ARN
export EKS_NODE_ROLE_ARN

echo "🏗️  Creating EKS cluster: $CLUSTER_NAME"

# Generate cluster configuration from template
envsubst < config/cluster-config.yaml > /tmp/cluster-config.yaml

# Create cluster
eksctl create cluster -f /tmp/cluster-config.yaml

echo "⏳ Waiting for cluster to be active..."
aws eks wait cluster-active --name $CLUSTER_NAME --region $AWS_REGION

echo "📦 Installing community add-ons..."

# Install Metrics Server
echo "📊 Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Install Fluent Bit
echo "📝 Installing Fluent Bit..."
kubectl create namespace amazon-cloudwatch || true
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml || echo "⚠️  Fluent Bit installation skipped (may require CloudWatch setup)"

# Cleanup
rm -f /tmp/cluster-config.yaml

echo "✅ EKS cluster created with all add-ons"
