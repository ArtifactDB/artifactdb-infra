variable "domain_name" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Opensearch cluster is deployed. Usually private."
  type        = list(string)
}

variable "access_subnet_ids" {
  description = "List of subnet IDs allowed to access Opensearch endpoint."
  type        = list(string)
}

variable "dedicated_master_enabled" {
  description = "Dedicated masters improved stability. Recommeneded for production."
  type        = bool
}

variable "instance_count" {
  description = "Number of data nodes. Depends on number of AZ, 2*AZs recommended for production."
}

variable "zone_awareness_enabled" {
  description = "Deploy in multiple AZ, recommended to production."
  type        = bool
}

variable "volume_size" {
  description = "Volume size in GiB attached to data nodes."
  type        = number
}

variable "volume_type" {
  description = "Volume type (eg. gp2, gp3, ...)"
  type        = string
  default     = "gp2"
  validation {
    condition     = contains(["gp2"], var.volume_type)
    error_message = "Module only support gp2 for now"
  }
}

variable "platform_name" {
  description = "ie. DemoDB"
  type        = string
}

variable "environment" {
  description = "ie. sandbox"
  type        = string
}

variable "platform_id" {
  description = "ie. demodb"
  type        = string
}

variable "kms_arn" {
  type = string
}

## TODO: deal with what comes when type is gp3 or iops provisioned
#variable "volume_iops" {
#  description = "IOPS (not applicable for volume_type gp2)"
#  type = string
#  nullable = true
#}
#
#variable "volume_throughput" {
#  description = "Only for volume_type gp3"
#  type = string
#  nullable = true
#}
