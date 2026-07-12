output "vpc_id" {
  value = module.networking.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "ecr_repository_url" {
  value = module.storage.ecr_repository_url
}

output "frontend_bucket_id" {
  value = module.storage.bucket_id
}

# COMMENTED OUT: module.cdn is currently disabled in main.tf (requires the backend
# ALB to exist first). Uncomment these together with module.cdn.
#
# output "cloudfront_domain_name" {
#   value = module.cdn.distribution_domain_name
# }
#
# output "cloudfront_distribution_id" {
#   value = module.cdn.distribution_id
# }

output "redis_endpoint" {
  value = module.database.redis_endpoint
}
