#!/bin/bash

# Script to grant EC2 instance type permissions to current IAM user

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔐 Granting EC2 Instance Type Permissions"
echo "=========================================="

# Get current user ARN
echo -e "\n${YELLOW}🔍 Getting current IAM user...${NC}"
CALLER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
USER_NAME=$(echo $CALLER_ARN | awk -F'/' '{print $NF}')

echo -e "${GREEN}Current user: $USER_NAME${NC}"
echo -e "${GREEN}ARN: $CALLER_ARN${NC}"

# Create EC2 instance type policy
echo -e "\n${YELLOW}📝 Creating EC2 instance type policy...${NC}"

cat > /tmp/ec2-instance-type-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:RunInstances",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:InstanceType": [
            "t2.micro",
            "t3.medium"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:TerminateInstances",
        "ec2:StopInstances",
        "ec2:StartInstances",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstanceStatus"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create policy (if doesn't exist)
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/EC2InstanceTypeAccess"

if aws iam get-policy --policy-arn $POLICY_ARN &>/dev/null; then
    echo -e "${GREEN}✅ Policy EC2InstanceTypeAccess already exists${NC}"
else
    aws iam create-policy \
        --policy-name EC2InstanceTypeAccess \
        --policy-document file:///tmp/ec2-instance-type-policy.json \
        --description "Allow launching t2.micro and t3.medium instances"
    
    echo -e "${GREEN}✅ Policy EC2InstanceTypeAccess created${NC}"
fi

# Attach policy to user
echo -e "\n${YELLOW}📎 Attaching policy to user...${NC}"
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn $POLICY_ARN 2>/dev/null || echo "⚠️  Policy may already be attached"

echo -e "${GREEN}✅ Policy attached to user${NC}"

# Clean up temp file
rm -f /tmp/ec2-instance-type-policy.json

# Verify attachment
echo -e "\n${YELLOW}🔍 Verifying policy attachment...${NC}"
if aws iam list-attached-user-policies --user-name "$USER_NAME" | grep -q "EC2InstanceTypeAccess"; then
    echo -e "${GREEN}✅ Verified: EC2InstanceTypeAccess is attached to $USER_NAME${NC}"
else
    echo -e "${RED}❌ Warning: Could not verify policy attachment${NC}"
fi

echo -e "\n${GREEN}🎉 Setup complete!${NC}"
echo -e "\n${YELLOW}📝 Summary:${NC}"
echo "User: $USER_NAME"
echo "Policy: EC2InstanceTypeAccess"
echo "Policy ARN: $POLICY_ARN"
echo ""
echo "You can now launch instances with the following types:"
echo "  • t2.micro"
echo "  • t3.medium"
