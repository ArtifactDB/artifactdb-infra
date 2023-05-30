resource "aws_security_group" "ingress" {
  description = "Allows access to the load balancer"
  name        = "eks-alb-sg-${var.lb_name}"
  vpc_id      = var.vpc_id
  lifecycle { ignore_changes = [tags] }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

# Setting rule to allow ALB access
resource "aws_security_group_rule" "https" {
  count             = var.ssl_cert_arn != null ? 1 : 0
  security_group_id = aws_security_group.ingress.id
  type              = "ingress"
  cidr_blocks       = var.ingress_cidr_blocks
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.ingress.id
  type              = "ingress"
  cidr_blocks       = var.ingress_cidr_blocks
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
}

resource "aws_lb" "lb" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnet_ids

  security_groups            = [aws_security_group.ingress.id]
  enable_deletion_protection = true

  access_logs {
    bucket  = var.logs_bucket
    prefix  = var.lb_name
    enabled = true
  }

}

resource "aws_lb_target_group" "ingress" {
  name     = "tg-${var.lb_name}"
  port     = var.ingress_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled = true
    matcher = "404" # by default we reach Traefik without ingress rules, so 404
  }
  tags = {
    ArtifactDBIngress = "true"
    OwnedBy           = "${var.cluster_name}"
  }
}

# Listeners: if SSL cert, we redirect from HTTP to HTTPS
# otherwise, just HTTP forward

resource "aws_lb_listener" "http" {
  count             = var.ssl_cert_arn == null ? 1 : 0
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_lb_listener" "https" {
  count             = var.ssl_cert_arn != null ? 1 : 0
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
  count             = var.ssl_cert_arn != null ? 1 : 0
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
