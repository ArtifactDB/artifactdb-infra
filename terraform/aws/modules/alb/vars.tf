variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type = string
}

variable "cluster_name" {
  type = string
}

variable "lb_name" {
  type = string
}

variable "internal" {
  description = "Defines whether the ALB is privately (true) or publicly (false) accessible"
  type = bool
  default = true
}

variable "ingress_cidr_blocks" {
  description = "List CIDR blocks from which traffic to ALB is allowed"
  type = list
}

variable "subnet_ids" {
  description = "Subnet IDs where the ingressable nodes are deployed"
  type = list
}

variable "lb_logs_bucket" {
  description = "Bucket name to store ALB logs"
  type = string
}

variable "ssl_cert_arn" {
  description = "SSL certificate, optional"
  type = string
  default = null
}
