#!/bin/bash

# Quick test script to verify the deployment

NAMESPACE="dapr-demo"

echo "🧪 Testing EKS Dapr Microservices"
echo "=================================="

# Check pod status
echo -e "\n📊 Pod Status:"
kubectl get pods -n $NAMESPACE

# Check Dapr components
echo -e "\n🔧 Dapr Components:"
kubectl get components -n $NAMESPACE

# Get publisher logs
echo -e "\n📝 Recent Publisher Logs:"
kubectl logs -n $NAMESPACE deployment/publisher -c publisher --tail=10

# Get subscriber logs
echo -e "\n📝 Recent Subscriber Logs:"
kubectl logs -n $NAMESPACE deployment/subscriber -c subscriber --tail=10

# Get Dapr sidecar logs
echo -e "\n📡 Publisher Dapr Sidecar Logs:"
kubectl logs -n $NAMESPACE deployment/publisher -c daprd --tail=10

echo -e "\n✅ Test complete!"
echo -e "\n💡 To follow logs in real-time:"
echo "   Publisher: kubectl logs -f -n $NAMESPACE deployment/publisher -c publisher"
echo "   Subscriber: kubectl logs -f -n $NAMESPACE deployment/subscriber -c subscriber"
