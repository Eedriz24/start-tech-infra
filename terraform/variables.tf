variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "alb_tag_name" {
  description = "The 'kubernetes.io/ingress.name' or Name tag applied to the ALB created by the AWS Load Balancer Controller for the backend Ingress. Used to look up the ALB DNS name after the app is deployed to EKS."
  type        = string
  default     = "starttech-backend-alb"
}

variable "mongodb_atlas_uri" {
  description = "MongoDB Atlas connection URI, injected into the backend via a Kubernetes Secret (not stored in state)."
  type        = string
  sensitive   = true
  default     = ""
}
