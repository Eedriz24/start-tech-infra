variable "bucket_name_prefix" {
  description = "Prefix for the S3 frontend bucket name (must include 'starttech-frontend-bucket')"
  type        = string
  default     = "starttech-frontend-bucket"
}

variable "ecr_repository_name" {
  type    = string
  default = "starttech-backend-api"
}

