#!/usr/bin/env bash
#
# deploy-infrastructure.sh
#
# Manual helper for deploying StartTech's infrastructure end-to-end.
# The apply is split into two phases because the CloudFront distribution's
# ALB origin depends on an ALB that is only created once the backend
# Ingress resource is applied to EKS (via the AWS Load Balancer Controller).
#
# Phase 1: VPC, EKS, S3, ECR, Redis
# Phase 2 (after backend is deployed to EKS): CloudFront (unified CDN)

set -euo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"
CLUSTER_NAME="starttech-cluster"
REGION="${AWS_REGION:-us-east-1}"

echo "=== Phase 1: Provisioning base infrastructure ==="
cd "$TF_DIR"
terraform init
terraform apply \
  -target=module.networking \
  -target=module.eks \
  -target=module.storage \
  -target=module.database



echo "=== Updating kubeconfig for $CLUSTER_NAME ==="
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "=== Deploying backend to EKS (Deployment/Service/Ingress) ==="
kubectl apply -f "$TF_DIR/../k8s/deployment.yaml"
kubectl apply -f "$TF_DIR/../k8s/service.yaml"
kubectl apply -f "$TF_DIR/../k8s/ingress.yaml"

echo "=== Waiting for ALB to be provisioned by AWS Load Balancer Controller ==="
sleep 60

echo "=== Phase 2: Provisioning CloudFront (unified CDN over S3 + ALB) ==="
terraform apply

echo "=== Done. Outputs: ==="
terraform output
