
data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "s3_lb_write" {
  statement {
    principals {
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
      type = "AWS"
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.lb_logs.arn}/*"
    ]
  }
}


resource aws_s3_bucket "lb_logs" {
  bucket = var.lb_logs_bucket
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.lb_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = data.aws_iam_policy_document.s3_lb_write.json
}

