variable "lb_logs_bucket" {
  description = "Bucket name to store ALB logs"
  type        = string
}

variable "kms_arn" {
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

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "platform_id" {
  description = "ie. demodb"
  type        = string
}