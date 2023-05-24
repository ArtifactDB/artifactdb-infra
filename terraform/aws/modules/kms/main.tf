resource "aws_kms_key" "kms" {
  description         = "KMS key for infra wide server-side encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_key_policy.json

}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/kms-${var.cluster_name}"
  target_key_id = aws_kms_key.kms.key_id
}

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
  depends_on = [aws_kms_key.kms]
  source     = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "kms_arn" = aws_kms_key.kms.arn
    })
  }

  kms_key_arn = aws_kms_key.kms.arn
  tags = {
    gprn          = "gprn:${var.environment}:platform:${var.platform_id}:secret:${local.module}"
    env           = var.environment
    platform_id   = var.platform_id
    platform_name = var.platform_name
  }
}

