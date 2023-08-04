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

variable "ecr_image_url" {
  description = "Docker image repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "v0.12.0"
}

variable "storage_amazon_prefix" {
  description = "ie. dev"
}

variable "storage_amazon_bucket" {
  type = string
}

variable "sealed_secrets_path" {
  description = "Sealed secrets yaml file path."
}

variable "ingress_regex_match" {
  type = string
}