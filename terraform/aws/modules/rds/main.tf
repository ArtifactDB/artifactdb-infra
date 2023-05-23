# shared RDS instance, with dedicated database per instance, and within
# an database, different schemas per sequence prefix

data "aws_vpc" "default" {
  id = var.vpc_id
}

resource "aws_db_subnet_group" "subnet_grp" {
  description = "RDS DB subnet group"
  name        = "subgrp-${var.db_name}"
  subnet_ids  = var.subnet_ids
}

resource "aws_security_group" "sg_db" {
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    cidr_blocks = var.ingress_cidr_blocks
    from_port   = var.db_port
    protocol    = "tcp"
    self        = "false"
    to_port     = var.db_port
  }
  name        = "rds-sg-${var.db_name}"
  description = "ArtifactDB RDS instance security group"
  vpc_id      = data.aws_vpc.default.id
}

resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "_!%"
}

# TODO: use secret manager more globally? See "post" module
resource "aws_secretsmanager_secret" "password" {
  # can't use GPRN notation with colon, not allowedim ASM
  name = "gprn-${var.env}-artifactdb--secret-psql"
  # trying to match ADB instance's secrets format/tags
  tags = {
    gprn     = "gprn:${var.env}:artifactdb::secret:psql"
    env      = var.env
    api_name = "artifactdb"
  }
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.master.result
}

resource "aws_db_instance" "psql" {
  allocated_storage                   = 20
  auto_minor_version_upgrade          = true
  availability_zone                   = "us-west-2b"
  backup_retention_period             = 7
  db_subnet_group_name                = aws_db_subnet_group.subnet_grp.name #"subgrp-artifactdb-dev"
  deletion_protection                 = false
  engine                              = "postgres"
  engine_version                      = "13.7"
  iam_database_authentication_enabled = false
  identifier                          = var.db_name
  instance_class                      = var.instance_type
  # TODO: can we use the custom KMS key instead of the aws/rds one? Needs permissions fine-tuning to allow using it
  # for RDS (which is shared accross ADB instances) but not more than RDS.
  #kms_key_id                            = "..."
  multi_az               = var.multi_az
  password               = aws_secretsmanager_secret_version.password.secret_string
  port                   = 5432
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
  storage_type           = "gp2"
  username               = "artifactdb"
  vpc_security_group_ids = [aws_security_group.sg_db.id]
}

