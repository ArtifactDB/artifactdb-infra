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

resource "kubernetes_namespace" "cerebro" {
  metadata {
    name = var.helm_deployment_namespace
  }
}

resource "null_resource" "apply_secrets" {
  provisioner "local-exec" {
    command = "kubectl -n ${kubernetes_namespace.cerebro.metadata[0].name} apply -f ${var.sealed_secrets_path}"
  }
  depends_on = [
    kubernetes_namespace.cerebro
  ]
}

resource "helm_release" "cerebro" {
  depends_on = [null_resource.apply_secrets]

  name       = var.helm_deployment_name
  namespace  = kubernetes_namespace.cerebro.metadata[0].name
  repository = var.helm_deployment_repo
  chart      = "cerebro"

  values = [<<EOF
image:
  repository: ${var.ecr_image_url}
  tag: ${var.image_tag}
  pullPolicy: IfNotPresent
config:
  hosts:
  - host: ${var.es_host}
    name: ${var.es_name}
nodeSelector:
  env: default
EOF
  ]
}

resource "kubectl_manifest" "middleware" {
  depends_on = [null_resource.apply_secrets]
  yaml_body  = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: ${var.helm_deployment_namespace}
spec:
  basicAuth:
    secret: authsecret
YAML
}

resource "kubectl_manifest" "ingress" {
  depends_on = [null_resource.apply_secrets, kubectl_manifest.middleware]
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
  - kind: Rule
    match: ${var.ingress_regex_match}
    middlewares:
    - name: basic-auth
      namespace: ${var.helm_deployment_namespace}
    services:
    - kind: Service
      name: ${var.helm_deployment_name}
      namespace: ${var.helm_deployment_namespace}
      port: 80

YAML
}