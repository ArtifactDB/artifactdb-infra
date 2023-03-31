resource "aws_eks_cluster" "eks_cluster" {
  encryption_config {
    provider {
      key_arn = var.kms_arn
    }

    resources = ["secrets"]
  }

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
  }

  name     = "artifactdb-dev"
  role_arn = "arn:aws:iam::197970530056:role/eksClusterRole"
  version  = "1.25"
  vpc_config {
    endpoint_private_access = true
    security_group_ids      = ["sg-0f855c517effb3513"]
    subnet_ids              = ["subnet-080ba8d0eccaef224", "subnet-0775b54dea36f3f03", "subnet-044a5b77c93e88216", "subnet-09d4362206cd23919", "subnet-0ab870a72475d5f3e", "subnet-0dbe6c58a2ec8bf15", "subnet-038742042bf0a6a62", "subnet-0a71c0939c03c641a"]
  }

}

