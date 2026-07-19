terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------- Networking ----------------
module "networking" {
  source = "./modules/networking"
  azs    = var.azs
}

# ---------------- EKS ----------------
module "eks" {
  source             = "./modules/eks"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  ci_iam_user_arn    = var.ci_iam_user_arn
}

# ---------------- Storage (S3 frontend + ECR) ----------------
module "storage" {
  source = "./modules/storage"
}

# ---------------- Backend ALB lookup ----------------
# COMMENTED OUT: The ALB is created by the AWS Load Balancer Controller (running on
# EKS) once the backend Ingress is deployed — which is out of scope for this repo.
# Uncomment once the backend app has been deployed to EKS and the ALB exists, so
# this data source can resolve it.
#
# data "aws_lb" "backend" {
#   tags = {
#     "elbv2.k8s.aws/cluster" = module.eks.cluster_name
#   }
#
#   depends_on = [module.eks]
# }

# ---------------- CDN (unified CloudFront: S3 + ALB origins) ----------------
# COMMENTED OUT: depends on data.aws_lb.backend above, which requires the ALB to
# already exist. Uncomment together with the data source once the backend is live.
#
# module "cdn" {
#   source                         = "./modules/cdn"
#   s3_bucket_regional_domain_name = module.storage.bucket_regional_domain_name
#   s3_bucket_id                   = module.storage.bucket_id
#   alb_dns_name                   = data.aws_lb.backend.dns_name
# }

# Bucket policy granting CloudFront (OAC) read access — defined at root level to
# avoid a circular dependency between the storage and cdn modules.
# COMMENTED OUT: depends on module.cdn.distribution_arn above.
#
# resource "aws_s3_bucket_policy" "frontend_oac" {
#   bucket = module.storage.bucket_id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid       = "AllowCloudFrontOAC"
#       Effect    = "Allow"
#       Principal = { Service = "cloudfront.amazonaws.com" }
#       Action    = "s3:GetObject"
#       Resource  = "${module.storage.bucket_arn}/*"
#       Condition = {
#         StringEquals = {
#           "AWS:SourceArn" = module.cdn.distribution_arn
#         }
#       }
#     }]
#   })
# }

# ---------------- Database (ElastiCache Redis) ----------------
module "database" {
  source                        = "./modules/database"
  vpc_id                        = module.networking.vpc_id
  vpc_cidr_block                = module.networking.vpc_cidr_block
  database_subnet_ids           = module.networking.database_subnet_ids
  eks_worker_security_group_id  = module.eks.cluster_security_group_id
}
