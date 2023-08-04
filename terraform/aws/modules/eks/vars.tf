variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = number
}

variable "kms_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "deploy_subnets" {
  description = "List of subnets IDs the EKS cluster is deployed on. Usually private subnets"
  type        = list(string)
}

variable "non_routable_subnets" {
  description = "List of subnets IDs the EKS cluster is using to deploy pods. Usually within 100.64.0.0/16"
  type        = list(string)
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "platform_name" {
  description = "ie. DemoDB"
  type        = string
}

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "platform_id" {
  description = "ie. demodb"
  type        = string
}

variable "additional_iam_roles_to_access_k8s" {
  description = "ie. {'arn:aws:iam::123456789012:role/some-dev-user-role' = {username = 'dev-user' group = 'system:master'}}"
  type        = map
}
