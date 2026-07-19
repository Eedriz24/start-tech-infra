# ---------------- IAM: EKS Control Plane ----------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "starttech-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------------- IAM: EKS Node Group ----------------
resource "aws_iam_role" "eks_node_role" {
  name = "starttech-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------------- EKS Cluster ----------------
resource "aws_eks_cluster" "starttech-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  bootstrap_self_managed_addons = false # matches existing live cluster — do not change

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }


  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "starttech-cluster"
  }

}

# ---------------- EKS Managed Node Group ----------------
resource "aws_eks_node_group" "starttech-node-group" {
  cluster_name    = aws_eks_cluster.starttech-cluster.name
  node_group_name = "starttech-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly_policy
  ]

  tags = {
    Name = "starttech-node-group"
  }
}

# ---------------- OIDC Provider (for IRSA, e.g. AWS LB Controller) ----------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.starttech-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.starttech-cluster.identity[0].oidc[0].issuer
}


# ---------------- EKS Access Entry for CI/CD IAM user ----------------
# Grants the CI IAM user cluster-admin access inside Kubernetes. Without this,
# only the identity that ran `terraform apply` gets automatic access — any
# other IAM user/role (like a GitHub Actions CI user) is authenticated by AWS
# but rejected by the Kubernetes API server itself (a separate authorization
# layer on top of IAM).
resource "aws_eks_access_entry" "ci_user" {
  cluster_name  = aws_eks_cluster.starttech-cluster.name
  principal_arn = var.ci_iam_user_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ci_user_admin" {
  cluster_name  = aws_eks_cluster.starttech-cluster.name
  principal_arn = var.ci_iam_user_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}