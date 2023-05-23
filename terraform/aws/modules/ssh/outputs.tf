output "ssh_key_arn" {
  value = aws_key_pair.kp.arn
}

output "ssh_key_name" {
  value = aws_key_pair.kp.key_name
}

output "private_key" {
  value     = tls_private_key.pk.private_key_pem
  sensitive = true
}

