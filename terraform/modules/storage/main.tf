resource "random_id" "suffix" {
  byte_length = 4
}

# ---------------- S3 Frontend Bucket ----------------
resource "aws_s3_bucket" "starttech-frontend-bucket" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"

  tags = {
    Name = "starttech-frontend-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.starttech-frontend-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.starttech-frontend-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.starttech-frontend-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# NOTE: The bucket policy granting CloudFront (OAC) read access is applied at the
# root module level (see terraform/main.tf), since it requires the CloudFront
# distribution ARN which is only known after the cdn module is created — this
# avoids a circular dependency between the storage and cdn modules.

# ---------------- ECR Repository ----------------
resource "aws_ecr_repository" "starttech-backend-api" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "starttech-backend-api"
  }
}
