variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type = string
}

variable "lb_name" {
  type = string
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
