variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type        = string
}

variable "lb_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "logs_bucket" {
  description = "Bucket name where ALB access logs can be stored"
  type        = string
}

variable "internal" {
  description = "Defines whether the ALB is privately (true) or publicly (false) accessible"
  type        = bool
  default     = true
}

variable "additional_ingress_cidr" {
  description = "Additional CIDR blocks for ingress rules."
  type        = list(string)
  default     = []
}

variable "ingress_port" {
  description = "Ingress port to forward traffic to"
  type        = number
  default     = 30080
}

variable "subnet_ids" {
  description = "Subnet IDs where the ingressable nodes are deployed"
  type        = list(string)
}

variable "ssl_cert_arn" {
  description = "SSL certificate, optional. If present, an HTTPS listener is added."
  type        = string
  default     = null
}
