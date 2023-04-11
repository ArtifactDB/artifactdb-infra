# shared RDS instance, with dedicated database per instance, and within
# an database, different schemas per sequence prefix

data "aws_vpc" "default" {
  id = var.vpc_id
}

resource "aws_db_subnet_group" "subnet_grp" {
  description = "RDS DB subnet group"
  name        = "subgrp-${var.db_name}"
  subnet_ids  = var.db_subnet_ids
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
    cidr_blocks = var.db_ingress_cidr_blocks
    from_port   = var.db_port
    protocol    = "tcp"
    self        = "false"
    to_port     = var.db_port
  }
  name = "rds-sg-${var.db_name}"
  description = "ArtifactDB RDS instance security group"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_db_instance" "psql" {
  identifier                            = var.db_name
  allocated_storage                     = "5"
  auto_minor_version_upgrade            = "true"
  backup_retention_period               = "7"
  copy_tags_to_snapshot                 = "true"
  db_subnet_group_name                  = aws_db_subnet_group.subnet_grp.name
  deletion_protection                   = "true"
  engine                                = "postgres"
  engine_version                        = var.db_version
  instance_class                        = var.db_instance_type
  multi_az                              = var.multi_az
  port                                  = 5432
  publicly_accessible                   = "false"
  storage_type                          = "gp2"
  username                              = "artifactdb"
  password                              = "abc123"  # TODO:
  vpc_security_group_ids                = [aws_security_group.sg_db.id]
  skip_final_snapshot = "true"
  #final_snapshot_identifier             = format("%s-%s-%s","final-snapshot-",var.db_name,formatdate("YYYYMMDDhhmmss", timestamp()))
  # TODO: each adb instance has its own KMS, but we can't use one KMS per database, KMS is for the whole instance
  # Use a olympus shared KMS for RDS (and opensearch?)
  #kms_key_id                            = aws_iam_policy.kms_policy.arn
  #storage_encrypted                     = "true"
}

