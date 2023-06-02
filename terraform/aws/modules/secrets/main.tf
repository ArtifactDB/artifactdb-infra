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

locals {
  image_name_to_pull = "bitnami/sealed-secrets-controller"
  image_tag_to_pull  = "v0.17.1"
  image_name_to_push = "${var.ecr_repository_name}/sealed-secrets-controller"
  image_tag_to_push  = "v0.17.1"
}
module "docker_pull_push_ecr" {
  source             = "../docker_pull_push_ecr"
  image_name_to_pull = local.image_name_to_pull
  image_tag_to_pull  = local.image_tag_to_pull
  image_name_to_push = local.image_name_to_push
  image_tag_to_push  = local.image_tag_to_push
  aws_account_id     = var.aws_account_id
  aws_region         = var.aws_region
}

resource "helm_release" "sealed" {
  depends_on       = [module.docker_pull_push_ecr]
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
    value = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  }
  set {
    name  = "image.repository"
    value = local.image_name_to_push
  }
  set {
    name  = "image.tag"
    value = local.image_tag_to_push
  }
}

