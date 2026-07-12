variable "vpc_id" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "eks_worker_security_group_id" {
  description = "Security group ID of the EKS worker nodes / cluster, allowed to reach Redis"
  type        = string
}

variable "vpc_cidr_block" {
  type = string
}
