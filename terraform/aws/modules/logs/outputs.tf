output "bucket_name" {
  value = aws_s3_bucket.lb_logs.bucket
}

output "ssm_parameter_names" {
  value     = module.aws_ssm_secrets.ssm_parameter_names
  sensitive = true
}

output "ssm_parameter_arns" {
  value     = module.aws_ssm_secrets.ssm_parameter_arns
  sensitive = false
}