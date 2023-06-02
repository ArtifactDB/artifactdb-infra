provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

resource "aws_iam_role" "cloudwatch_agent" {
  name = "cloudwatch-agent-${var.cluster_name}"
  lifecycle { ignore_changes = [permissions_boundary] }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:${var.helm_deployment_namespace}:cloudwatch-agent"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "helm_release" "cloudwatch_agent" {
  name       = var.helm_deployment_name
  namespace  = var.helm_deployment_namespace
  chart      = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  values = [
    yamlencode({
      awsRegion   = var.aws_region
      clusterName = var.cluster_name
      rbac = {
        create = true
      }
      serviceAccount = {
        create = true
        name   = "cloudwatch-agent"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cloudwatch_agent.arn
        }
      }
    })
  ]
}

