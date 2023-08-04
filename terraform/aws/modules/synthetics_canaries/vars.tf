variable "canary_name" {
  description = "The name for the canary."
  type        = string
}

variable "canary_script" {
  description = "The script for the canary."
  type        = string
}

variable "runtime_version" {
  description = "The version of the runtime to use for the canary."
  type        = string
  default     = "syn-1.0"
}

variable "schedule_expression" {
  description = "A rate or cron expression that defines how often the canary is to run."
  type        = string
  default     = "rate(5 minutes)"
}

variable "subnet_ids" {
  description = "The IDs of the subnets where the canary should run."
  type        = list(string)
}

variable "security_group_ids" {
  description = "The IDs of the security groups to associate with the canary."
  type        = list(string)
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

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "applications" {
  description = "List of applications to monitor."
  type = list(object({
    hostname = string
    path     = string
  }))
}