data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "es_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    # TODO: for now full access, but we need fine-grain access, per instance (IRSA, svc role)
    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"]
  }
}

data "aws_subnet" "es_target" {
  for_each = toset(var.access_subnet_ids)
  id       = each.value
}


resource "aws_security_group" "es_sg" {
  name   = "es-sg-${var.domain_name}"
  vpc_id = [for s in data.aws_subnet.es_target : s.vpc_id][0]
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = values(data.aws_subnet.es_target).*.cidr_block
  }
}

resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type            = var.instance_type
    dedicated_master_enabled = var.dedicated_master_enabled
    instance_count           = var.instance_count
    zone_awareness_enabled   = var.zone_awareness_enabled
  }

  access_policies = data.aws_iam_policy_document.es_policy.json

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.es_sg.id]
  }

  ebs_options {
    # TODO: maybe not required/allowed for all instance type?
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = var.volume_type
    #iops = var.volume_iops
    #throughput = var.volume_throughput
  }

}

# Send secrets to SSM Parameter Store
locals {
  module = basename(abspath(path.module))
}
module "aws_ssm_secrets" {
  source = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "endpoint" = aws_opensearch_domain.opensearch.endpoint
    })
  }

  kms_key_arn = var.kms_arn
  tags = {
    gprn          = "gprn:${var.environment}:platform:${var.platform_id}:secret:${local.module}"
    env           = var.environment
    platform_id   = var.platform_id
    platform_name = var.platform_name
  }
}

# TODO: there's also a serverless option for opensearch, which supports KMS per collection (one instance has a dedicated KMS key)
