output "secrets" {
  value     = local.parsed_parameters
  sensitive = true
}