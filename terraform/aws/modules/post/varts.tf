variable "terragrunt_dir" {
  description = "Path to terragrunt modules (terragrunt is used to export outputs)"
  type = string
}

variable "module_dir" {
  description = "Path to terraform (*form) modules (to locate python dumper script)"
  type = string
}

variable "modules" {
  description = "Map of {module_name => module_path} considered for output registration"
  type = map
}

variable "olympus_ns" {
  description = "Kubernetes namespace where all output will be stored as a secret. Used by Olympus"
  type = string
}

variable "olympus_secret_name" {
  description = "Kubernetes secret name"
  type = string
  default = "tfoutputs"
}

variable "platform_name" {
  description = "Name of the platform being deployed. Used to generate corresponding GPRN. No spaces allowed."
  type = string
}

variable "env" {
  description = "Environment targetted by the platform being deployed. Used to generate corresponding GPRN. One of: wip, dev, uat, prd"
  type = string
}
