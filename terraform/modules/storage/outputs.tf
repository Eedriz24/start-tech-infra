output "bucket_id" {
  value = aws_s3_bucket.starttech-frontend-bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.starttech-frontend-bucket.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.starttech-frontend-bucket.bucket_regional_domain_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.starttech-backend-api.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.starttech-backend-api.name
}
