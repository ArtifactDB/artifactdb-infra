variable "pg_host" {
  type = string
  description = "PostgreSQL instance hostname"
}

variable "pg_port" {
  type = number
  default = 5432
}

variable "pg_auth_database" {
  type = string
  description = "Database name used to authenticate master user"
}

variable "pg_username" {
  type = string
  description = "Master username, allowed to create databases, roles, etc..."
}

variable "pg_database" {
  type = string
  description = "Database name dedicated for the instance schemas, tables, etc..."
}

variable "pg_role" {
  type = string
}

variable "pg_owner" {
  type = string
}

variable "pg_passwd" {
  type = string
  sensitive = true
}
