resource "aws_kms_key" "kms" {
  count               = var.kms_arn == "" ? 1 : 0
  description         = "KMS key for infra wide server-side encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_key_policy.json
}

data "aws_kms_key" "existing_kms" {
  count  = var.kms_arn == "" ? 0 : 1
  key_id = var.kms_arn
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/kms-${var.cluster_name}"
  target_key_id = var.kms_arn == "" ? aws_kms_key.kms[0].key_id : data.aws_kms_key.existing_kms[0].key_id
}

locals { kms_arn = var.kms_arn == "" ? aws_kms_key.kms[0].arn : data.aws_kms_key.existing_kms[0].arn }

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "root"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid = "autoscaling"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
        "arn:aws:iam::${var.aws_account_id}:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
      ]
    }
    actions = [
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
  }
}

locals {
  module = basename(abspath(path.module))
}

module "aws_ssm_secrets" {
  source = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "kms_arn" = local.kms_arn
    })
  }

  kms_key_arn = local.kms_arn
  tags = {
    gprn = "gprn:${var.environment}:platform:${var.platform_id}:secret:${local.module}"
    env  = var.environment
  }
}

