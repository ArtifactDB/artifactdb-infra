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

resource "aws_lb" "lb" {
  name               = var.lb_name
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnet_ids

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = var.lb_name
    enabled = true
  }

  depends_on = [aws_s3_bucket.lb_logs]
}

resource "aws_lb_target_group" "ingress" {
  name     = var.lb_name
  port     = 30080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# Listeners: if SSL cert, we redirect from HTTP to HTTPS
# otherwise, just HTTP forward

resource "aws_lb_listener" "http" {
  count = var.ssl_cert_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_lb_listener" "https" {
  count = var.ssl_cert_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_lb_listener" "redirect" {
  count = var.ssl_cert_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
