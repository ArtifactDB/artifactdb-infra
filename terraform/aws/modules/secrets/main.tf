terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
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

resource "helm_release" "sealed" {
  count            = var.secret_controller == "sealed-secrets" ? 1 : 0
  namespace        = var.helm_deployment_namespace
  create_namespace = false

  repository = "https://bitnami-labs.github.io/sealed-secrets"
  name       = var.helm_deployment_name
  chart      = "sealed-secrets"
  version    = "2.0.2"

  # image has moved so overwrite default helm values
  set {
    name  = "image.registry"
    value = element(split("/", var.ecr_image_url), 0)
  }
  set {
    name  = "image.repository"
    value = join("/", slice(split("/", var.ecr_image_url), 1, length(split("/", var.ecr_image_url))))
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
}

