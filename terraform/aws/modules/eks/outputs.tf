output "oidc_provider_arn" {
  value     = aws_iam_openid_connect_provider.oidc.arn
}

output "ca" {
  value     = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "endpoint" {
  value     = aws_eks_cluster.eks_cluster.endpoint
}

