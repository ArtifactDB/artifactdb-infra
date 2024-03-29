variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
}

variable "helm_deployment_name" {
  type = string
}

variable "helm_deployment_namespace" {
  type = string
}

variable "environment" {
  description = "ie. sandbox"
  type        = string
}