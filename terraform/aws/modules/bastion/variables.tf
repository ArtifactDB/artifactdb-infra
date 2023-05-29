variable "bastion_subnet_id" {
  description = "Subnet ID for the bastion host. It should be a public subnet."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "private_key" {
  type = string
}