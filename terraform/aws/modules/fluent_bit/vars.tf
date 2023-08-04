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
  type    = string
  default = "fluent-bit"
}

variable "helm_deployment_namespace" {
  type = string
}

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "docker_repo" {
  description = "Alternate Docker repo to pull the image from"
  type        = string
  default     = "aws-for-fluent-bit" # Docker Hub
}

variable "log_retention_days" {
  description = "ie. 30"
  type        = string
  default     = 30
}

variable "image_tag" {
  type = string
}

variable "ecr_image_url" {
  type = string
}