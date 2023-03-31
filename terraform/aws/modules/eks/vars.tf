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

variable "ingress_port" {
  type = number
  default = 30080
}

variable "ingress_cidr_blocks" {
  description = "List CIDR blocks from which traffic can flow within the ingres controller. Usually matching what the ALB is targetting"
  type = list
}
