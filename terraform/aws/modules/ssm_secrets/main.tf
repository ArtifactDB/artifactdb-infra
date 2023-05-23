resource "aws_ssm_parameter" "secret" {
  for_each = var.secrets

  name   = each.key
  type   = "SecureString"
  value  = each.value
  key_id = var.kms_key_arn
  tags   = var.tags
}
