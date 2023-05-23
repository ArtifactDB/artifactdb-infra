# IAM role the EKS cluster can assume
resource "aws_iam_role" "eks_cluster_role" {
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"eks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
  description        = "Allows access to other AWS service resources that are required to operate clusters managed by EKS."
  inline_policy {
  }

  managed_policy_arns  = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
  max_session_duration = 3600
  name                 = "eks-cluster-role-${var.cluster_name}"
  path                 = "/"

}


# Extra security group (placeholder for now)
resource "aws_security_group" "extra_sg" {
  description = "Extra sg rules"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  name   = "eks-cluster-sg-${var.cluster_name}-extra"
  vpc_id = var.vpc_id
}

resource "aws_eks_cluster" "eks_cluster" {
  encryption_config {
    provider {
      key_arn = var.kms_arn
    }

    resources = ["secrets"]
  }

  #kubernetes_network_config {
  #  ip_family         = "ipv4"
  #  service_ipv4_cidr = "172.20.0.0/16"
  #}

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version
  vpc_config {
    endpoint_private_access = "true"
    endpoint_public_access  = "false"
    security_group_ids      = [aws_security_group.extra_sg.id]
    subnet_ids              = var.deploy_subnets
  }

}

# Idendity provider to support IRSA auth.
data "tls_certificate" "cert" {
  url = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.eks_cluster.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
}

#resource "aws_eks_addon" "ebs_csi" {
#  cluster_name = aws_eks_cluster.eks_cluster.name
#  addon_name   = "aws-ebs-csi-driver"
#  timeouts {
#    create = "5m"
#  }
#}

#resource "aws_eks_addon" "coredns" {
#  cluster_name = aws_eks_cluster.eks_cluster.name
#  addon_name   = "coredns"
#  timeouts {
#    create = "5m"
#  }
#}


# Custom EKS addon install, for these (deployment based) we don't have nodes
# yet so they stay in DEGRADED state, which is fine, but aws_eks_addon module wants ACTIVE only...
resource "null_resource" "addon_ebs_csi" {
  triggers = {
    id = aws_eks_cluster.eks_cluster.arn
  }
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            aws eks describe-addon --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name aws-ebs-csi-driver && exit 0
            aws eks create-addon --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name aws-ebs-csi-driver
            out=`aws eks wait addon-active --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name aws-ebs-csi-driver 2>&1`
            if [ "$?" != "0" ]
            then
                echo "Addon not ACTIVE, check DEGRADED"
                echo $out | grep DEGRADED
                if [ "$?" != "0" ]
                then
                    echo "Addon in expected state: $out"
                    exit 255
                fi
            fi
            echo "************************************************************************************"
EOT
  }
}

resource "null_resource" "addon_coredns" {
  triggers = {
    id = aws_eks_cluster.eks_cluster.arn
  }
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            aws eks describe-addon --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name coredns && exit 0
            aws eks create-addon --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name coredns
            out=`aws eks wait addon-active --profile ${var.aws_profile} --region ${var.aws_region} --cluster-name ${var.cluster_name} --addon-name coredns 2>&1`
            if [ "$?" != "0" ]
            then
                echo "Addon not ACTIVE, check DEGRADED"
                echo $out | grep DEGRADED
                if [ "$?" != "0" ]
                then
                    echo "Addon in expected state: $out"
                    exit 255
                fi
            fi
            echo "************************************************************************************"
EOT
  }
}

data "aws_subnet" "deploy_subnets" {
  for_each = toset(var.deploy_subnets)
  id       = each.value
}

# Allow k8s access from same subnets
resource "aws_security_group_rule" "k8s_access" {
  description       = "k8s access"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = values(data.aws_subnet.deploy_subnets).*.cidr_block
  security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

# Send secrets to SSM Parameter Store
locals {
  module = basename(abspath(path.module))
}
module "aws_ssm_secrets" {
  source = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "oidc_provider_arn" = aws_iam_openid_connect_provider.oidc.arn
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
#### Enabling IAM Roles for Service Accounts  for aws-node pod
#data "aws_iam_policy_document" "cluster_assume_role_policy" {
#  statement {
#    actions = ["sts:AssumeRoleWithWebIdentity"]
#    effect  = "Allow"
#
#    condition {
#      test     = "StringEquals"
#      variable = "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub"
#      values   = ["system:serviceaccount:kube-system:aws-node"]
#    }
#
#    principals {
#      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
#      type        = "Federated"
#    }
#  }
#}
#
#resource "aws_iam_role" "cluster" {
#  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
#  name               = format("irsa-%s-aws-node", aws_eks_cluster.cluster.name)
#}


