variable "secrets" {
  description = "A map of secrets to be stored in AWS SSM Parameter Store."
  type        = map(string)
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to encrypt the secrets."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the SSM parameters."
  type        = map(string)
  default     = {}
}
