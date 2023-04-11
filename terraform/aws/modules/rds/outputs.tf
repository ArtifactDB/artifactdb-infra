output "db_address" {
  value = aws_db_instance.psql.address
}

output "admin" {
  value = aws_db_instance.psql.username
}

output "passwd" {
  value = aws_db_instance.psql.password
  sensitive = true
}
