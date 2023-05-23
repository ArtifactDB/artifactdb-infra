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
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://bitnami-labs.github.io/sealed-secrets"
  name       = "sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.0.2"

  # image has moved so overwrite default helm values
  set {
    name  = "image.registry"
    value = "docker.io"
  }
  set {
    name  = "image.repository"
    value = "bitnami/sealed-secrets-controller"
  }
  set {
    name  = "image.tag"
    value = "v0.17.1"
  }
}

