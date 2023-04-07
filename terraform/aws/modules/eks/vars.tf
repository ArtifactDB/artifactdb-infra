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
  type = list
}

variable "non_routable_subnets" {
  description = "List of subnets IDs the EKS cluster is using to deploy pods. Usually within 100.64.0.0/16"
  type = list
}

