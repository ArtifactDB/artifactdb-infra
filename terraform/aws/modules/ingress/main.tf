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
    value = var.docker_repo
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

  set {
    name = "additionalArguments[3]"
    value = "--global.checknewversion=false"
  }

  set {
    name = "additionalArguments[4]"
    value = "--global.sendanonymoususage=false"
  }

}

