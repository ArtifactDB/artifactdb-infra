terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
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

resource "kubernetes_namespace" "chartmuseum" {
  metadata {
    name = var.helm_deployment_namespace
  }
}

resource "null_resource" "apply_secrets" {
  provisioner "local-exec" {
    command = "kubectl -n ${kubernetes_namespace.chartmuseum.metadata[0].name} apply -f ${var.sealed_secrets_path}"
  }
  depends_on = [
    kubernetes_namespace.chartmuseum
  ]
}


resource "kubectl_manifest" "ingress" {
  depends_on = [null_resource.apply_secrets]
  yaml_body  = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ${var.helm_deployment_name}
  namespace: ${var.helm_deployment_namespace}
spec:
  entryPoints:
    - web
  routes:
    - match: ${var.ingress_regex_match}
      kind: Rule
      # before other routes, that point to API endpoints
      priority: 100
      services:
      - name: ${var.helm_deployment_name}
        namespace: ${var.helm_deployment_namespace}
        port: 8080
YAML
}

resource "helm_release" "chartmuseum" {
  depends_on = [null_resource.apply_secrets, kubectl_manifest.ingress]
  name       = var.helm_deployment_name
  namespace  = kubernetes_namespace.chartmuseum.metadata[0].name
  chart      = "./chartmuseum-2.14.2.tgz"

  values = [<<EOF
env:
  open:
    DISABLE_API: false
    STORAGE: amazon
    STORAGE_AMAZON_BUCKET: ${var.storage_amazon_bucket}
    STORAGE_AMAZON_PREFIX: ${var.storage_amazon_prefix}
    STORAGE_AMAZON_REGION: ${var.aws_region}

  # previously manually created
  existingSecret: ${var.helm_deployment_name}-secret
  existingSecretMappings:
    AWS_ACCESS_KEY_ID: aws-access-key
    AWS_SECRET_ACCESS_KEY: aws-secret-access-key

fullnameOverride: ${var.helm_deployment_name}

ingress:
  enabled: false

image:
  repository: ${var.ecr_image_url}
  tag: ${var.image_tag}

nodeSelector:
  env: default

EOF
  ]
}
