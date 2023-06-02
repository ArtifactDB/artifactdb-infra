data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "adb_policy" {
  name = "policy-${var.instance_id}-${var.env}"
  path = "/"

  tags = {
    Name         = "${var.instance_id}-${var.env}"
    Version      = var.instance_version
    InstanceID   = var.instance_id
    InstanceName = var.instance_name
  }

  # Goal: give adb instances full permissions on its own bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "StorageAccess"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "${var.kms_arn}",
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
        ]
      },
    ]
  })
}


resource "aws_iam_role" "adb_role" {
  count = var.irsa ? 1 : 0
  name  = "role-${var.instance_id}-${var.env}"
  lifecycle {
    ignore_changes = [permissions_boundary]
  }
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IRSA",
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.oidc_provider}:aud": "sts.amazonaws.com",
                    "${var.oidc_provider}:sub": "system:serviceaccount:${var.namespace}:${var.service_account}"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "adb_access" {
  count      = var.irsa ? 1 : 0
  role       = aws_iam_role.adb_role[count.index].name
  policy_arn = aws_iam_policy.adb_policy.arn
}


resource "aws_iam_user_policy_attachment" "adb_access" {
  count      = var.irsa ? 0 : 1
  user       = var.iam_user_name
  policy_arn = aws_iam_policy.adb_policy.arn
}
