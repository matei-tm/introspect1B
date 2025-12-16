#!/bin/bash

# Quick test script to verify the deployment

NAMESPACE="dapr-demo"
CLOUDWATCH_NAMESPACE="amazon-cloudwatch"

echo "🧪 Testing EKS Dapr Microservices"
echo "=================================="

# Check pod status
echo -e "\n📊 Pod Status:"
kubectl get pods -n $NAMESPACE

# Check CloudWatch Container Insights
echo -e "\n📊 CloudWatch Container Insights Status:"
kubectl get pods -n $CLOUDWATCH_NAMESPACE

# Check Dapr components
echo -e "\n🔧 Dapr Components:"
kubectl get components -n $NAMESPACE

# Get product logs
echo -e "\n📝 Recent Product Logs:"
kubectl logs -n $NAMESPACE deployment/product -c product --tail=10

# Get order logs
echo -e "\n📝 Recent Order Logs:"
kubectl logs -n $NAMESPACE deployment/order -c order --tail=10

# Get Dapr sidecar logs
echo -e "\n📡 Product Dapr Sidecar Logs:"
kubectl logs -n $NAMESPACE deployment/product -c daprd --tail=10

# Check CloudWatch agent logs
echo -e "\n📊 CloudWatch Agent Status:"
kubectl logs -n $CLOUDWATCH_NAMESPACE daemonset/cloudwatch-agent --tail=10 2>/dev/null || echo "⚠️  CloudWatch agent logs not available"

# Check Fluent Bit logs
echo -e "\n📊 Fluent Bit Status:"
kubectl logs -n $CLOUDWATCH_NAMESPACE daemonset/fluent-bit --tail=10 2>/dev/null || echo "⚠️  Fluent Bit logs not available"

echo -e "\n✅ Test complete!"
echo -e "\n💡 To follow logs in real-time:"
echo "   Product: kubectl logs -f -n $NAMESPACE deployment/product -c product"
echo "   Order: kubectl logs -f -n $NAMESPACE deployment/order -c order"
echo "   CloudWatch Agent: kubectl logs -f -n $CLOUDWATCH_NAMESPACE daemonset/cloudwatch-agent"
echo "   Fluent Bit: kubectl logs -f -n $CLOUDWATCH_NAMESPACE daemonset/fluent-bit"
