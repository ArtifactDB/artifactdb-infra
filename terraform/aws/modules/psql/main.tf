
provider "postgresql" {
  scheme   = "awspostgres"
  host = var.pg_host
  username = var.pg_username
  database = var.pg_auth_database
  port     = var.pg_port
  #password = "..."  # set via $PGPASSWORD
  superuser = false
  sslmode = "disable"
}

resource "postgresql_role" "role" {
  name     = var.pg_role
  login    = true
  password = var.pg_passwd
}

resource "postgresql_database" "sequences" {
  name              = var.pg_database
  owner             = var.pg_owner
  lc_collate        = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true
}

# grant for instance's role
resource "postgresql_grant" "grant" {
  database    = var.pg_database
  role        = var.pg_role
  object_type = "database"
  privileges  = ["CONNECT","CREATE","TEMPORARY"]
  depends_on = [
    postgresql_database.sequences
  ]
}

# grant for master user as well
resource "postgresql_grant" "grant_master" {
  database    = var.pg_database
  role        = var.pg_role
  object_type = "database"
  privileges  = ["CONNECT","CREATE","TEMPORARY"]
  depends_on = [
    postgresql_database.sequences
  ]
}
