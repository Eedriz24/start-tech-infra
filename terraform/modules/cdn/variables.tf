variable "s3_bucket_regional_domain_name" {
  type = string
}

variable "s3_bucket_id" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the backend Application Load Balancer"
  type        = string
}
