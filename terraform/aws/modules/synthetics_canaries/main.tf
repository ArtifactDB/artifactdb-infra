resource "aws_s3_bucket" "bucket" {
  bucket = "${var.canary_name}-synthetics-canary-results"
  force_destroy = true
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir = var.canary_script
  output_path = "./${var.canary_name}.zip"
}

resource "aws_synthetics_canary" "canary" {
  name                 = var.canary_name
  artifact_s3_location = "s3://${aws_s3_bucket.bucket.bucket}"
  execution_role_arn   = aws_iam_role.canary_execution_role.arn
  handler              = "canary_script.handler"
  runtime_version      = var.runtime_version
  zip_file             = data.archive_file.zip.output_path
  start_canary         = true

  schedule {
    expression = var.schedule_expression
  }
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
  run_config {
    timeout_in_seconds = 30
    environment_variables = {
      "NODE_TLS_REJECT_UNAUTHORIZED" = "0",
      "APPLICATIONS" = jsonencode(var.applications)
    }
  }
}

resource "aws_iam_role" "canary_execution_role" {
  lifecycle {ignore_changes = [permissions_boundary]}
  name = "${var.canary_name}_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "canary_execution_policy" {
  name = "${var.canary_name}_canary_execution_policy"
  role = aws_iam_role.canary_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListAllMyBuckets",
            "xray:PutTraceSegments"
        ],
        "Resource": [
            "*"
        ]
    },
    {
        "Effect": "Allow",
        "Resource": "*",
        "Action": "cloudwatch:PutMetricData",
        "Condition": {
            "StringEquals": {
                "cloudwatch:namespace": "CloudWatchSynthetics"
            }
        }
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
        ],
        "Resource": [
            "*"
        ]
    }
  ]
}
EOF
}