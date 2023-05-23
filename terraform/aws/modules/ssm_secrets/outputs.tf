output "ssm_parameter_names" {
  description = "The names of the created SSM parameters."
  value       = [for name in aws_ssm_parameter.secret : name]
}

output "ssm_parameter_arns" {
  description = "The ARNs of the created SSM parameters."
  value       = [for arn in aws_ssm_parameter.secret : arn.arn]
}
