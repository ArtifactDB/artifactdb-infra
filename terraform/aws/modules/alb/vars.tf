variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type = string
}

variable "lb_name" {
  type = string
}

variable "logs_bucket" {
  description = "Bucket name where ALB access logs can be stored"
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

variable "ssl_cert_arn" {
  description = "SSL certificate, optional. If present, an HTTPS listener is added."
  type = string
  default = null
}
