variable "ingress_controller" {
  description = "Name of the k8s controller to deploy"
  type        = string
  validation {
    # TODO: nginx
    condition     = contains(["traefik"], var.ingress_controller)
    error_message = "Unsupported ingress controller"
  }
}

variable "num_replicas" {
  type = number
}

variable "ingress_port" {
  type = number
  # matching nodegroup var too
  default = 30080
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "ecr_image_url" {
  type = string
}