output "cluster_name" {
  value = aws_eks_cluster.starttech-cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.starttech-cluster.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.starttech-cluster.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.starttech-cluster.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_name" {
  value = aws_eks_node_group.starttech-node-group.node_group_name
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.starttech-cluster.vpc_config[0].cluster_security_group_id
}
