variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_version" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "kms_arn" {
  type        = string
  description = "KMS ARN, used to encrypt bucket"
}

variable "irsa" {
  type        = bool
  description = "Active IRSA based authentication for ArtifactDB instance's service account. If true, an OIDC provider must be specified, otherwise an IAM user name is required."
}

variable "oidc_provider" {
  type        = string
  description = "If IRSA is used, OIDC provider domain attached to the EKS cluster (without https:// or arn:...)."
  default     = null
}

variable "iam_user_name" {
  type        = string
  description = "Name of the IAM user when authentication is not based on IRSA (eg. local dev deployment not running on the cloud)"
  default     = null
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace where ArtifactDB instance's service account is declared, when IRSA is used (to match IAM role for IRSA)."
  default     = null
}

variable "service_account" {
  type        = string
  description = "ArtifactDB instance's service account name when IRSA is used."
  default     = "charon"
}

