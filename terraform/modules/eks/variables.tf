variable "cluster_name" {
  type    = string
  default = "starttech-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

# ---------------- EKS Node Group Variables ----------------
variable "node_instance_types" {
  type    = list(string)
  default = ["t3.micro"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "ci_iam_user_arn" {
  description = "ARN of the IAM user/role running CI/CD (e.g. GitHub Actions) that needs Kubernetes API access"
  type        = string
}