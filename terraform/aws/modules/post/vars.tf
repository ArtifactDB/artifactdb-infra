variable "parameter_path" {
  description = "The path prefix for the parameters to retrieve from AWS SSM Parameter Store."
  type        = string
}

variable "terragrunt_dir" {
  description = "Path to terragrunt modules (terragrunt is used to export outputs)"
  type        = string
}

variable "olympus_ns" {
  description = "Kubernetes namespace where all output will be stored as a secret. Used by Olympus"
  type        = string
}

variable "olympus_secret_name" {
  description = "Kubernetes secret name"
  type        = string
  default     = "tfoutputs"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region (ie. us-west-2)"
  type        = string
}

variable "aws_profile" {
  description = "AWS profile (name from .aws/credentials)"
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