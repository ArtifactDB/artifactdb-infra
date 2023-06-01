variable "secret_controller" {
  description = "Name of the secret controller to deploy"
  type        = string
  validation {
    condition     = contains(["sealed-secrets"], var.secret_controller)
    error_message = "Unsupported ingress controller"
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "ecr_repository_name" {
  type = string
}

variable "helm_deployment_name" {
  type = string
  default = "sealed-secrets"
}

variable "helm_deployment_namespace" {
  type = string
  default = "kube-system"
}