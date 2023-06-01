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
  image_name_to_pull = "traefik"
  image_tag_to_pull = "v2.9.8"
  image_name_to_push = "${var.ecr_repository_name}/traefik"
  image_tag_to_push = "v2.9.8"
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

resource "helm_release" "traefik" {
  count            = var.ingress_controller == "traefik" ? 1 : 0
  namespace        = "ingress" # TODO: as a variable
  create_namespace = true

  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "21.2.0"

  set {
    name  = "ports.web.nodePort"
    value = var.ingress_port
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "image.repository"
    value = module.docker_pull_push_ecr.ecr_image_name
  }
  set {
    name  = "image.tag"
    value = local.image_tag_to_push
  }

  set {
    name  = "deployment.replicas"
    value = var.num_replicas
  }

  set {
    name  = "nodeSelector.env"
    value = "default"
  }

  set {
    name = "globalArguments"
    value = "null"
  }

  set {
    name  = "additionalArguments[0]"
    value = "--providers.kubernetesingress.labelselector=ci!=true"
  }

  set {
    name  = "additionalArguments[1]"
    value = "--providers.kubernetescrd.labelselector=ci!=true"
  }

  set {
    name  = "additionalArguments[2]"
    value = "--providers.kubernetescrd.allowcrossnamespace=true"
  }

}

