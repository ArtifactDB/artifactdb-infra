variable "aws_account_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "platform_name" {
  description = "ie. DemoDB"
  type        = string
}

variable "platform_id" {
  description = "ie. demodb"
  type        = string
}


variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "kms_arn" {
  description = "The ARN of the existing KMS key"
  default     = "" # Set a default value to avoid "value is null" error.
}