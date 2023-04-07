variable "secret_controller" {
  description = "Name of the secret controller to deploy"
  type = string
  validation {
    condition     = contains(["sealed-secrets"], var.secret_controller)
    error_message = "Unsupported ingress controller"
    }
}

