#!/usr/bin/env bash
#
# cleanup-orphaned-resources.sh
#
# Directly deletes ALL starttech-* resources via AWS CLI, bypassing Terraform
# entirely (since state is empty/inconsistent with what's actually in AWS).
# Run this once, then start fresh with `terraform apply` from clean state.
#
# ORDER MATTERS for VPC teardown:
#   node group -> EKS cluster -> NAT gateway -> release EIP -> detach/delete IGW
#   -> delete non-default subnets -> delete non-main route tables
#   -> delete non-default security groups -> delete VPC

# set -uo pipefail  # NOTE: no -e, we want to continue past individual failures

# REGION="${AWS_REGION:-us-east-1}"
# VPC_IDS=("vpc-014228737a77a504e" "vpc-0f3a4ea34a0327c1c" "vpc-0df17b5b03ad44402" "vpc-00b8d6f2d1b24624c")

# echo "=== 1. Deleting EKS node group + cluster ==="
# aws eks delete-nodegroup --cluster-name starttech-cluster --nodegroup-name starttech-node-group --region "$REGION" || true
# echo "Waiting for node group deletion (this can take several minutes)..."
# aws eks wait nodegroup-deleted --cluster-name starttech-cluster --nodegroup-name starttech-node-group --region "$REGION" || true

# aws eks delete-cluster --name starttech-cluster --region "$REGION" || true
# echo "Waiting for cluster deletion..."
# aws eks wait cluster-deleted --name starttech-cluster --region "$REGION" || true

# echo "=== 2. Deleting ElastiCache cluster + subnet group ==="
# aws elasticache delete-cache-cluster --cache-cluster-id starttech-redis --region "$REGION" || true
# echo "Waiting for cache cluster deletion..."
# aws elasticache wait cache-cluster-deleted --cache-cluster-id starttech-redis --region "$REGION" || true
# aws elasticache delete-cache-subnet-group --cache-subnet-group-name starttech-redis-subnet-group --region "$REGION" || true

# echo "=== 3. Deleting ECR repository ==="
# aws ecr delete-repository --repository-name starttech-backend-api --force --region "$REGION" || true

# echo "=== 4. Deleting IAM roles (detach policies first) ==="
# for role in starttech-eks-cluster-role starttech-eks-node-role; do
#   echo "-- Detaching policies from $role"
#   for policy_arn in $(aws iam list-attached-role-policies --role-name "$role" --query "AttachedPolicies[].PolicyArn" --output text 2>/dev/null); do
#     aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" || true
#   done
#   echo "-- Deleting role $role"
#   aws iam delete-role --role-name "$role" || true
# done

# echo "=== 5. Deleting all starttech S3 buckets ==="
# for bucket in $(aws s3 ls | awk '{print $3}' | grep starttech); do
#   echo "-- Emptying and deleting bucket: $bucket"
#   aws s3 rm "s3://$bucket" --recursive || true
#   aws s3api delete-bucket --bucket "$bucket" --region "$REGION" || true
# done

# echo "=== 6. Tearing down each VPC (networking children first, then the VPC) ==="
# for VPC_ID in "${VPC_IDS[@]}"; do
#   echo ""
#   echo "--- Processing VPC: $VPC_ID ---"

#   # Check VPC still exists before proceeding
#   if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$REGION" &>/dev/null; then
#     echo "VPC $VPC_ID no longer exists, skipping."
#     continue
#   fi

#   # -- NAT Gateways (and their EIPs) --
#   for nat_id in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending" --query "NatGateways[].NatGatewayId" --output text --region "$REGION"); do
#     echo "Deleting NAT gateway: $nat_id"
#     aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" --region "$REGION" || true
#   done

#   if [[ -n "${nat_id:-}" ]]; then
#     echo "Waiting 60s for NAT gateway deletion to propagate..."
#     sleep 60
#   fi

#   # -- Release Elastic IPs tagged for this stack --
#   for alloc_id in $(aws ec2 describe-addresses --filters "Name=tag:Name,Values=starttech-nat-eip" --query "Addresses[].AllocationId" --output text --region "$REGION"); do
#     echo "Releasing EIP: $alloc_id"
#     aws ec2 release-address --allocation-id "$alloc_id" --region "$REGION" || true
#   done

#   # -- Internet Gateway: detach then delete --
#   for igw_id in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text --region "$REGION"); do
#     echo "Detaching + deleting IGW: $igw_id"
#     aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$VPC_ID" --region "$REGION" || true
#     aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" --region "$REGION" || true
#   done

#   # -- Subnets --
#   for subnet_id in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text --region "$REGION"); do
#     echo "Deleting subnet: $subnet_id"
#     aws ec2 delete-subnet --subnet-id "$subnet_id" --region "$REGION" || true
#   done

#   # -- Route tables (skip main table, it's deleted automatically with the VPC) --
#   for rt_id in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" --output text --region "$REGION"); do
#     echo "Deleting route table: $rt_id"
#     aws ec2 delete-route-table --route-table-id "$rt_id" --region "$REGION" || true
#   done

#   # -- Security groups (skip default, it's deleted automatically with the VPC) --
#   for sg_id in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text --region "$REGION"); do
#     echo "Deleting security group: $sg_id"
#     aws ec2 delete-security-group --group-id "$sg_id" --region "$REGION" || true
#   done

#   # -- Finally, the VPC itself --
#   echo "Deleting VPC: $VPC_ID"
#   aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" || true
# done

# echo ""
# echo "=== Cleanup complete. Verify with: ==="
# echo "aws ec2 describe-vpcs --filters \"Name=tag:Name,Values=starttech-vpc\""
# echo "aws eks list-clusters"
# echo "aws iam list-roles --query \"Roles[?contains(RoleName, 'starttech')].RoleName\""
# echo "aws ecr describe-repositories --repository-names starttech-backend-api"
# echo "aws elasticache describe-cache-clusters --query \"CacheClusters[?CacheClusterId=='starttech-redis']\""
# echo "aws s3 ls | grep starttech"