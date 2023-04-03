output "oidc_provider_arn" {
  value     = aws_iam_openid_connect_provider.oidc.arn
}

output "ca" {
  value     = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "endpoint" {
  value     = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  value     = aws_eks_cluster.eks_cluster.name
}

output "cluster_version" {
  value     = aws_eks_cluster.eks_cluster.version
}

