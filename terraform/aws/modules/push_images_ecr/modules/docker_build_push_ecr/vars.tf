variable "image_name" {
  description = "The name of the Docker image"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image"
  type        = string
}

variable "dockerfile_path" {
  description = "The path to the Dockerfile"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_profile" {
  description = "AWS profile name"
  type        = string
}