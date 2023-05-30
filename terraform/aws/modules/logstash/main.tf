provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

locals {
  image_name = "logstash"
  image_tag  = "opensearch"
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

data "tls_certificate" "oidc_cert" {
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "s3_logstash" {
  name        = "s3_logstash_policy_${var.logstash_environment}"
  description = "Policy for Logstash to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.lb_logs_bucket}",
          "arn:aws:s3:::${var.lb_logs_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "elasticsearch_logstash" {
  name        = "elasticsearch_logstash_policy_${var.logstash_environment}"
  description = "Policy for Logstash to access Elasticsearch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet",
          "es:ESHttpDelete"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:es:us-west-2:${var.aws_account_id}:domain/${var.lb_logs_bucket}/*"
      }
    ]
  })
}

resource "aws_iam_role" "logstash_role" {
  name = "logstash-role-${var.logstash_environment}"
  lifecycle { ignore_changes = [permissions_boundary] }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:${var.helm_deployment_namespace}:logstash-${var.logstash_environment}"
        }
      }
    }
  ]
}
EOF
}

module "docker_build_and_push" {
  source          = "../docker_build_push_ecr"
  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  aws_profile     = var.aws_profile
  image_name      = "${var.ecr_repository_name}/${local.image_name}"
  image_tag       = local.image_tag
  dockerfile_path = "./"
}

resource "aws_iam_role_policy_attachment" "logstash_es_access" {
  role       = aws_iam_role.logstash_role.name
  policy_arn = aws_iam_policy.elasticsearch_logstash.arn
}

resource "aws_iam_role_policy_attachment" "logstash_s3_access" {
  role       = aws_iam_role.logstash_role.name
  policy_arn = aws_iam_policy.s3_logstash.arn
}

resource "kubernetes_namespace" "logstash" {
  metadata {
    name = var.helm_deployment_namespace
  }
}

resource "helm_release" "logstash" {
  depends_on = [module.docker_build_and_push, kubernetes_namespace.logstash]
  name       = var.helm_deployment_name
  namespace  = var.helm_deployment_namespace
  repository = "https://helm.elastic.co"
  chart      = "logstash"

  values = [yamlencode({
    image    = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}/${local.image_name}"
    imageTag = local.image_tag
    rbac = {
      create = true
      serviceAccountAnnotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.logstash_role.arn
      }
      serviceAccountName = "logstash-${var.logstash_environment}"
    }
    persistence = {
      enabled = true
    }
    nodeSelector = {
      "eks.amazonaws.com/nodegroup" = "default"
    }
    logstashConfig = {
      "logstash.yml" = <<-EOT
        http.host: 0.0.0.0
        xpack.monitoring.enabled: false
      EOT
    }
    logstashPipeline = {
      "s3-to-es.conf" = <<-EOT
    input {
      s3 {
        bucket => "${var.lb_logs_bucket}"
        region => "${var.aws_region}"
      }
    }
    filter {
      grok {
        match => [ "message", '%%{TIMESTAMP_ISO8601:timestamp} %%{NOTSPACE:loadbalancer} %%{IP:client_ip}:%%{NUMBER:client_port:int} (?:%%{IP:backend_ip}:%%{NUMBER:backend_port:int}|-) %%{NUMBER:request_processing_time:float} %%{NUMBER:backend_processing_time:float} %%{NUMBER:response_processing_time:float} (?:%%{NUMBER:elb_status_code:int}|-) (?:%%{NUMBER:backend_status_code:int}|-) %%{NUMBER:received_bytes:int} %%{NUMBER:sent_bytes:int} "(?:%%{WORD:verb}|-) (?:%%{GREEDYDATA:request}|-) (?:HTTP/%%{NUMBER:httpversion}|-( )?)" "%%{DATA:userAgent}"( %%{NOTSPACE:ssl_cipher} %%{NOTSPACE:ssl_protocol})?']
      }
      grok {
        match => [ "request", '%%{URIPROTO:uri_proto}://(?:%%{USER:user}(?::[^@]*)?@)?(?:%%{URIHOST:uri_domain})?(%%{URIPATH:uri_path})?(?:%%{URIPARAM:uri_param})?' ]
      }
      date {
        match => [ "timestamp", ISO8601 ]
      }
      fingerprint {
        method => "SHA1"
      }
    }
    output {
      opensearch {
        hosts => ["https://${var.opensearch_endpoint}:443"]
        ssl_certificate_verification => true
        index => "${var.lb_logs_bucket}_%%{+YYYY.MM}"
      }
    }
      EOT
      "logstash.conf" = <<-EOT
    input {
      beats {
        port => 5044
      }
    }
      EOT
    }
  })]
}
