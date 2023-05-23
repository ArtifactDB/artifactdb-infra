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

variable "lb_logs_bucket" {
  description = "Bucket name to store ALB logs"
  type        = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint."
  type        = string
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
}