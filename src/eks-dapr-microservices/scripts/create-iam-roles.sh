#!/bin/bash

# Script to create IAM roles for EKS cluster and node groups

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔐 Creating IAM Roles for EKS"
echo "=============================="

# Variables
EKS_CLUSTER_ROLE_NAME="EKSClusterRole"
EKS_NODE_ROLE_NAME="EKSNodeRole"

# Create EKS Cluster Role
echo -e "\n${YELLOW}📋 Creating EKS Cluster Role...${NC}"

# Check if cluster role exists
if aws iam get-role --role-name $EKS_CLUSTER_ROLE_NAME &>/dev/null; then
    echo -e "${GREEN}✅ EKS Cluster Role already exists${NC}"
else
    # Create trust policy for EKS cluster
    cat > /tmp/eks-cluster-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role
    aws iam create-role \
        --role-name $EKS_CLUSTER_ROLE_NAME \
        --assume-role-policy-document file:///tmp/eks-cluster-trust-policy.json \
        --description "IAM role for EKS cluster"
    
    echo -e "${GREEN}✅ Created EKS Cluster Role${NC}"
fi

# Attach AmazonEKSClusterPolicy
echo -e "\n${YELLOW}📎 Attaching AmazonEKSClusterPolicy...${NC}"
aws iam attach-role-policy \
    --role-name $EKS_CLUSTER_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy || true
echo -e "${GREEN}✅ Policy attached${NC}"

# Get cluster role ARN
CLUSTER_ROLE_ARN=$(aws iam get-role --role-name $EKS_CLUSTER_ROLE_NAME --query 'Role.Arn' --output text)
echo -e "${GREEN}Cluster Role ARN: $CLUSTER_ROLE_ARN${NC}"

# Create EKS Node Role
echo -e "\n${YELLOW}📋 Creating EKS Node Role...${NC}"

# Check if node role exists
if aws iam get-role --role-name $EKS_NODE_ROLE_NAME &>/dev/null; then
    echo -e "${GREEN}✅ EKS Node Role already exists${NC}"
else
    # Create trust policy for EKS nodes (EC2)
    cat > /tmp/eks-node-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role
    aws iam create-role \
        --role-name $EKS_NODE_ROLE_NAME \
        --assume-role-policy-document file:///tmp/eks-node-trust-policy.json \
        --description "IAM role for EKS worker nodes"
    
    echo -e "${GREEN}✅ Created EKS Node Role${NC}"
fi

# Attach required policies to node role
echo -e "\n${YELLOW}📎 Attaching policies to Node Role...${NC}"

# AmazonEKSWorkerNodePolicy
aws iam attach-role-policy \
    --role-name $EKS_NODE_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy || true
echo -e "${GREEN}✅ AmazonEKSWorkerNodePolicy attached${NC}"

# AmazonEKS_CNI_Policy
aws iam attach-role-policy \
    --role-name $EKS_NODE_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy || true
echo -e "${GREEN}✅ AmazonEKS_CNI_Policy attached${NC}"

# AmazonEC2ContainerRegistryReadOnly
aws iam attach-role-policy \
    --role-name $EKS_NODE_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly || true
echo -e "${GREEN}✅ AmazonEC2ContainerRegistryReadOnly attached${NC}"

# Get node role ARN
NODE_ROLE_ARN=$(aws iam get-role --role-name $EKS_NODE_ROLE_NAME --query 'Role.Arn' --output text)
echo -e "${GREEN}Node Role ARN: $NODE_ROLE_ARN${NC}"

# Clean up temp files
rm -f /tmp/eks-cluster-trust-policy.json
rm -f /tmp/eks-node-trust-policy.json

echo -e "\n${GREEN}🎉 IAM Roles Setup Complete!${NC}"
echo -e "\n${YELLOW}📝 Summary:${NC}"
echo "Cluster Role: $EKS_CLUSTER_ROLE_NAME"
echo "  ARN: $CLUSTER_ROLE_ARN"
echo "  Policy: AmazonEKSClusterPolicy"
echo ""
echo "Node Role: $EKS_NODE_ROLE_NAME"
echo "  ARN: $NODE_ROLE_ARN"
echo "  Policies:"
echo "    - AmazonEKSWorkerNodePolicy"
echo "    - AmazonEKS_CNI_Policy"
echo "    - AmazonEC2ContainerRegistryReadOnly"
echo ""
echo -e "${YELLOW}💡 Use these roles when creating your EKS cluster:${NC}"
echo "  eksctl create cluster --role-arn $CLUSTER_ROLE_ARN \\"
echo "    --nodegroup-name eks-lt-ng-public --node-role-arn $NODE_ROLE_ARN ..."
