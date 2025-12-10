#!/bin/bash

# Script to create VPC for EKS cluster

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-dapr-demo-cluster}"
VPC_NAME="${VPC_NAME:-eks-dapr-vpc}"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_1_CIDR="10.0.1.0/24"
PUBLIC_SUBNET_2_CIDR="10.0.2.0/24"

echo "🌐 Creating VPC for EKS Cluster"
echo "================================"

# Create VPC
echo -e "\n${YELLOW}📦 Creating VPC...${NC}"
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME},{Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared}]" \
    --query 'Vpc.VpcId' \
    --output text)

echo -e "${GREEN}✅ VPC created: $VPC_ID${NC}"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames \
    --region $AWS_REGION

# Create Internet Gateway
echo -e "\n${YELLOW}🌍 Creating Internet Gateway...${NC}"
IGW_ID=$(aws ec2 create-internet-gateway \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$VPC_NAME-igw}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo -e "${GREEN}✅ Internet Gateway created: $IGW_ID${NC}"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region $AWS_REGION

echo -e "${GREEN}✅ Internet Gateway attached to VPC${NC}"

# Get availability zones
AZ1=$(aws ec2 describe-availability-zones \
    --region $AWS_REGION \
    --query 'AvailabilityZones[0].ZoneName' \
    --output text)

AZ2=$(aws ec2 describe-availability-zones \
    --region $AWS_REGION \
    --query 'AvailabilityZones[1].ZoneName' \
    --output text)

# Create Public Subnet 1
echo -e "\n${YELLOW}📍 Creating Public Subnet 1 in $AZ1...${NC}"
SUBNET_1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_1_CIDR \
    --availability-zone $AZ1 \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$VPC_NAME-public-subnet-1},{Key=kubernetes.io/role/elb,Value=1},{Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo -e "${GREEN}✅ Public Subnet 1 created: $SUBNET_1_ID${NC}"

# Enable auto-assign public IP for Subnet 1
aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_1_ID \
    --map-public-ip-on-launch \
    --region $AWS_REGION

echo -e "${GREEN}✅ Auto-assign public IPv4 enabled for Subnet 1${NC}"

# Create Public Subnet 2
echo -e "\n${YELLOW}📍 Creating Public Subnet 2 in $AZ2...${NC}"
SUBNET_2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $PUBLIC_SUBNET_2_CIDR \
    --availability-zone $AZ2 \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$VPC_NAME-public-subnet-2},{Key=kubernetes.io/role/elb,Value=1},{Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo -e "${GREEN}✅ Public Subnet 2 created: $SUBNET_2_ID${NC}"

# Enable auto-assign public IP for Subnet 2
aws ec2 modify-subnet-attribute \
    --subnet-id $SUBNET_2_ID \
    --map-public-ip-on-launch \
    --region $AWS_REGION

echo -e "${GREEN}✅ Auto-assign public IPv4 enabled for Subnet 2${NC}"

# Create Route Table
echo -e "\n${YELLOW}🗺️  Creating Route Table...${NC}"
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-public-rt}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo -e "${GREEN}✅ Route Table created: $ROUTE_TABLE_ID${NC}"

# Create route to Internet Gateway
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $AWS_REGION

echo -e "${GREEN}✅ Route to Internet Gateway added${NC}"

# Associate Route Table with Subnet 1
aws ec2 associate-route-table \
    --subnet-id $SUBNET_1_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $AWS_REGION

echo -e "${GREEN}✅ Route Table associated with Subnet 1${NC}"

# Associate Route Table with Subnet 2
aws ec2 associate-route-table \
    --subnet-id $SUBNET_2_ID \
    --route-table-id $ROUTE_TABLE_ID \
    --region $AWS_REGION

echo -e "${GREEN}✅ Route Table associated with Subnet 2${NC}"

# Save VPC information to file
cat > /tmp/vpc-info.txt <<EOF
VPC_ID=$VPC_ID
SUBNET_1_ID=$SUBNET_1_ID
SUBNET_2_ID=$SUBNET_2_ID
IGW_ID=$IGW_ID
ROUTE_TABLE_ID=$ROUTE_TABLE_ID
EOF

echo -e "\n${GREEN}🎉 VPC Setup Complete!${NC}"
echo -e "\n${YELLOW}📝 VPC Information:${NC}"
echo "VPC ID: $VPC_ID"
echo "Internet Gateway: $IGW_ID"
echo "Public Subnet 1: $SUBNET_1_ID (AZ: $AZ1)"
echo "Public Subnet 2: $SUBNET_2_ID (AZ: $AZ2)"
echo "Route Table: $ROUTE_TABLE_ID"
echo ""
echo -e "${YELLOW}💾 VPC information saved to /tmp/vpc-info.txt${NC}"
