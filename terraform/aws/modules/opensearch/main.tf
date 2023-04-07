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


resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type = var.instance_type
    dedicated_master_enabled = var.dedicated_master_enabled
    instance_count = var.instance_count
    zone_awareness_enabled = var.zone_awareness_enabled
  }

  access_policies = data.aws_iam_policy_document.es_policy.json

  vpc_options {
    subnet_ids = var.subnet_ids
  }

  ebs_options {
    # TODO: maybe not required/allowed for all instance type?
    ebs_enabled = true
    volume_size = var.volume_size
    #volume_type = var.volume_type
    #iops = var.volume_iops
    #throughput = var.volume_throughput
  }

}

# TODO: there's also a serverless option for opensearch, which supports KMS per collection (one instance has a dedicated KMS key)
