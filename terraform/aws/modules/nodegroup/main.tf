locals {
  create_iam_role = var.eks_node_group_role_arn == "" ? 1 : 0
}

resource "aws_iam_role" "node_role" {
  count = local.create_iam_role
  name = "eks-node-group-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  lifecycle {ignore_changes = [permissions_boundary]}
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  count = local.create_iam_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role[0].name

}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  count = local.create_iam_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  count = local.create_iam_role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  count = local.create_iam_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node_role[0].name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  count = local.create_iam_role
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_role[0].name
}

# Allow ingressable node to self-register to ALB when booting
data "aws_iam_policy_document" "alb_register" {
  count = local.create_iam_role
  statement {
    effect    = "Allow"
    actions   = ["elasticloadbalancing:RegisterTargets"]
    resources = ["*"]
    # allows to register into any TG owned by the platform deployment
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/OwnedBy"
      values   = ["${var.cluster_name}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources", "tag:GetTagValues", "tag:GetTagKeys"]
    resources = ["*"] # TODO: any way to restrict which tags we can read?
  }
}


# We need to allow to use the default KMS key
# setup on the account, in addition to our custom one
# because the default k8s storage class doesn't specify any
# and we would need to override it to set our own, or create
# another class and reference it when needed. For now it's
# simpler and safer to specify both keys to support all cases
# out of the box.
data "aws_ebs_default_kms_key" "current" {count = local.create_iam_role}
data "aws_ebs_encryption_by_default" "current" {count = local.create_iam_role}

# Allow node to provision EBS volume with encryption enabled
data "aws_iam_policy_document" "ebs_encrypt" {
  count = local.create_iam_role
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:RevokeGrant",
      "kms:GenerateDataKey",
      "kms:ReEncryptTo",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyPair",
      "kms:CreateGrant",
      "kms:ReEncryptFrom",
      "kms:ListGrants"
    ]
    resources = compact([
      var.kms_arn,
      data.aws_ebs_encryption_by_default.current[0].enabled ? data.aws_ebs_default_kms_key.current[0].key_arn : null
    ])
  }
}

resource "aws_iam_policy" "alb_register" {
  count = local.create_iam_role
  name   = "policy-alb-register-${var.cluster_name}"
  path   = "/"
  policy = data.aws_iam_policy_document.alb_register[0].json
}

resource "aws_iam_policy" "ebs_encrypt" {
  count = local.create_iam_role
  name   = "policy-ebs-encrypt-${var.cluster_name}"
  path   = "/"
  policy = data.aws_iam_policy_document.ebs_encrypt[0].json
}

resource "aws_iam_role_policy_attachment" "alb_register" {
  count = local.create_iam_role
  policy_arn = aws_iam_policy.alb_register[0].arn
  role       = aws_iam_role.node_role[0].name
}

resource "aws_iam_role_policy_attachment" "ebs_encrypt" {
  count = local.create_iam_role
  policy_arn = aws_iam_policy.ebs_encrypt[0].arn
  role       = aws_iam_role.node_role[0].name
}


resource "aws_security_group" "ingress" {
  count       = var.ingressed ? 1 : 0
  description = "ingress to k8s nodes"
  vpc_id      = var.vpc_id
  name        = "eks-ingress-sg-${var.cluster_name}"
  lifecycle {ignore_changes = [tags]}

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = var.ingress_cidr_blocks
    from_port   = var.ingress_port
    to_port     = var.ingress_port
    protocol    = "tcp"
  }

  dynamic "ingress" {
    for_each = toset(var.lb_security_groups)
    content {
      from_port   = var.ingress_port
      to_port     = var.ingress_port
      protocol    = "tcp"
      security_groups = [ingress.value]
    }
  }
}

# Self-annotation with correct ENIConfig to enable pod assignment
data "template_file" "eks_user_data" {
  template = file("bootstrap_user_data.sh.tpl")
  vars = {
    cluster_endpoint = "${var.cluster_endpoint}"
    cluster_name     = "${var.cluster_name}"
    cluster_ca       = "${var.cluster_ca}"
    eks_ami          = "${var.eks_ami}"
    node_group_name  = "${var.node_group_name}"
    ingressed        = "${var.ingressed}"
  }
}

resource "aws_launch_template" "launch_template" {
  name                   = "lt-${var.cluster_name}-${var.node_group_name}-eks"
  image_id               = var.eks_ami
  key_name               = var.ssh_key_name
  user_data              = base64encode(data.template_file.eks_user_data.rendered)
  update_default_version = true
  lifecycle {ignore_changes = [tags]}
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = "true"
      encrypted             = "true"
      kms_key_id            = var.kms_arn
      volume_size           = var.volume_size
      volume_type           = var.volume_type
    }
  }

  vpc_security_group_ids = flatten([
    var.cluster_security_group_id,                           # joins control plane
    aws_security_group.remote_ssh.id,                        # SSH to nodes for debug
    var.ingressed ? [aws_security_group.ingress[0].id] : [], # allows traffic to ingressable node
  ])

}

data "aws_subnet" "ssh_target" {
  for_each = toset(var.ssh_access_subnet_ids)
  id       = each.value
}

resource "aws_security_group" "remote_ssh" {
  description = "Defines SG from which SSH to nodes is allowed"
  vpc_id      = var.vpc_id
  lifecycle {ignore_changes = [tags]}

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = values(data.aws_subnet.ssh_target).*.cidr_block
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
  }

  name = "eks-remote-ssh-sg-${var.cluster_name}"
}

resource "aws_eks_node_group" "nodegroup" {
  cluster_name = var.cluster_name
  # version and LT image_id are exclusive: if we select the AMI we're using to
  # corresponding EKS AMI version matching the cluster.  if not, we let EKS
  # selecting the one it wants. Same of AMI type.
  version         = var.eks_ami == null ? var.cluster_version : null
  ami_type        = var.eks_ami == null ? var.ami_type : null
  node_group_name = var.node_group_name
  node_role_arn   = local.create_iam_role == 1 ? aws_iam_role.node_role[0].arn : var.eks_node_group_role_arn
  instance_types  = var.instance_types
  subnet_ids      = var.subnet_ids

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  # pods declare tolerations when ingressed is needed, env=default means
  # "deploy me on an ingressable node". Not well named, I know...
  labels = merge(
    var.ingressed ? {
      env = "default"
    } : {}
  )

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  timeouts {}

  update_config {
    max_unavailable = var.max_unavailable
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEBSCSIDriverPolicy,
    aws_iam_role_policy_attachment.CloudWatchAgentServerPolicy,
  ]
}


## Allow traffic toward ingress controller
#resource "aws_security_group_rule" "ingress" {
#  description = "ingress to k8s nodes"
#  type        = "ingress"
#  from_port   = var.ingress_port
#  to_port     = var.ingress_port
#  protocol    = "tcp"
#  cidr_blocks = var.ingress_cidr_blocks
#  security_group_id = aws_eks_node_group.nodegroup.resources[0].remote_access_security_group_id
#}

