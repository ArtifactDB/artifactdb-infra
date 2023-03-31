resource "aws_kms_key" "kms" {
  description = "KMS key for infra wide server-side encryption"
  enable_key_rotation = true
  policy = data.aws_iam_policy_document.kms_key_policy.json

}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/kms-${var.cluster_name}"
  target_key_id = aws_kms_key.kms.key_id
}

data "aws_iam_policy_document" "kms_key_policy" {
    statement {
      sid = "kms_key_policy"
      effect = "Allow"
      principals {
          type = "AWS"
          identifiers = ["arn:aws:iam::${var.account_id}:root"]
      }
      actions = ["kms:*"]
      resources = ["*"]
    }
}

