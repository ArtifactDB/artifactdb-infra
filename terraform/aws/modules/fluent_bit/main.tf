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


resource "aws_iam_role" "fluent_bit" {
  name = "fluent-bit-${var.cluster_name}"
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
          "${replace(var.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:${var.helm_deployment_namespace}:${var.helm_deployment_name}"
        }
      }
    }
  ]
}
EOF
}


resource "aws_iam_policy" "fluent_bit_cloudwatch" {
  name        = "fluent-bit-cloudwatch-${var.cluster_name}"
  description = "Policy for Fluent Bit to interact with CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch.arn
}

resource "kubernetes_namespace" "fluent_bit" {
  metadata {
    name = var.helm_deployment_namespace
  }
}

locals {
  image_name_to_pull = "public.ecr.aws/aws-observability/aws-for-fluent-bit"
  image_tag_to_pull = "2.28.4"
  image_name_to_push = "gp/${var.environment}/fluent-bit"
  image_tag_to_push = "2.28.4"
}
module "docker_pull_push_ecr" {
  source = "../docker_pull_push_ecr"
  image_name_to_pull = local.image_name_to_pull
  image_tag_to_pull = local.image_tag_to_pull
  image_name_to_push = local.image_name_to_push
  image_tag_to_push = local.image_tag_to_push
  aws_account_id = var.aws_account_id
  aws_region = var.aws_region
}

resource "helm_release" "fluent_bit" {
  depends_on = [kubernetes_namespace.fluent_bit, module.docker_pull_push_ecr]
  name       = var.helm_deployment_name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  #version    = "4.0.6"
  namespace  = kubernetes_namespace.fluent_bit.metadata[0].name

  values = [
    templatefile("./values.tpl", {
      log_group_name = "/aws/eks/${var.cluster_name}/cluster/fluentbit-cloudwatch/logs"
      log_group_template = "/aws/containerinsights/${var.cluster_name}/$kubernetes['namespace_name']"
      region       = var.aws_region
      service_account_name = var.helm_deployment_name
      docker_repo = module.docker_pull_push_ecr.ecr_image_name
      image_tag = local.image_tag_to_push
      service_account_role_arn = aws_iam_role.fluent_bit.arn
    })
  ]
}
