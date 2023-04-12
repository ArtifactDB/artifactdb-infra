output "address" {
  value = aws_db_instance.psql.address
}

output "endpoint" {
  value = aws_db_instance.psql.endpoint
}


output "username" {
  value = aws_db_instance.psql.username
}

output "password" {
  value = aws_db_instance.psql.password
  sensitive = true
}
