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

resource "helm_release" "stakater" {
  name       = var.helm_deployment_name
  namespace  = var.helm_deployment_namespace
  chart      = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  version    = "v1.0.29"

  values = [
    templatefile("./values.tpl", {
      resource_label_selector = "reloader=enabled"
    })
  ]

}
