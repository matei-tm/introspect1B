#!/bin/bash

# Script to grant EKS admin access to current IAM user

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔐 Granting EKS Admin Access"
echo "============================"

# Get current user ARN
echo -e "\n${YELLOW}🔍 Getting current IAM user...${NC}"
CALLER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
USER_NAME=$(echo $CALLER_ARN | awk -F'/' '{print $NF}')

echo -e "${GREEN}Current user: $USER_NAME${NC}"
echo -e "${GREEN}ARN: $CALLER_ARN${NC}"

# Create custom EKS admin policy
echo -e "\n${YELLOW}📝 Creating EKS admin policy...${NC}"

cat > /tmp/eks-admin-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create policy (if doesn't exist)
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/EKSFullAdminAccess"

if aws iam get-policy --policy-arn $POLICY_ARN &>/dev/null; then
    echo -e "${GREEN}✅ Policy EKSFullAdminAccess already exists${NC}"
else
    aws iam create-policy \
        --policy-name EKSFullAdminAccess \
        --policy-document file:///tmp/eks-admin-policy.json \
        --description "Full admin access to all EKS clusters"
    
    echo -e "${GREEN}✅ Policy EKSFullAdminAccess created${NC}"
fi

# Attach policy to user
echo -e "\n${YELLOW}📎 Attaching policy to user...${NC}"
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn $POLICY_ARN 2>/dev/null || echo "⚠️  Policy may already be attached"

echo -e "${GREEN}✅ Policy attached to user${NC}"

# Clean up temp file
rm -f /tmp/eks-admin-policy.json

# Verify attachment
echo -e "\n${YELLOW}🔍 Verifying policy attachment...${NC}"
if aws iam list-attached-user-policies --user-name "$USER_NAME" | grep -q "EKSFullAdminAccess"; then
    echo -e "${GREEN}✅ Verified: EKSFullAdminAccess is attached to $USER_NAME${NC}"
else
    echo -e "${RED}❌ Warning: Could not verify policy attachment${NC}"
fi

echo -e "\n${GREEN}🎉 Setup complete!${NC}"
echo -e "\n${YELLOW}📝 Summary:${NC}"
echo "User: $USER_NAME"
echo "Policy: EKSFullAdminAccess"
echo "Policy ARN: $POLICY_ARN"
echo ""
echo "You now have full admin access to all EKS clusters, including:"
echo "  • Create, update, and delete clusters"
echo "  • Manage node groups"
echo "  • Configure cluster authentication"
echo "  • Access cluster endpoints"
echo "  • Manage all EKS resources"
