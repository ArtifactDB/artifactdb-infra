variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type = string
}

variable "db_version" {
  description = "DB engine version"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the DB instance is deployed. Needs to follow DB subnet groups requirements (eg. at least 2 AZs)"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type used to deployed the database (does not need to be beefy)"
  type        = string
}

variable "multi_az" {
  description = "Specify whether the deployment is multi AZ or not (recommended for production)."
  type        = bool
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

variable "kms_arn" {
  type = string
}

variable "additional_ingress_cidr" {
  description = "Additional CIDR blocks for ingress rules."
  type        = list(string)
  default     = []
}