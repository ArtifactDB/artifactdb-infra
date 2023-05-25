data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "s3_lb_write" {
  statement {
    principals {
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
      type        = "AWS"
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.lb_logs.arn}/*"
    ]
  }
}


resource "aws_s3_bucket" "lb_logs" {
  bucket = var.lb_logs_bucket
}

#resource "aws_s3_bucket_acl" "acl" {
#  bucket = aws_s3_bucket.lb_logs.id
#  acl    = "private"
#}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket     = aws_s3_bucket.lb_logs.id
  policy     = data.aws_iam_policy_document.s3_lb_write.json
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.lb_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


locals {
  module = basename(abspath(path.module))
}
module "aws_ssm_secrets" {
  source = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "lb_logs_bucket" = aws_s3_bucket.lb_logs.bucket
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