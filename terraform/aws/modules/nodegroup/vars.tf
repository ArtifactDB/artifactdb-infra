variable "vpc_id" {
  description = "VPC ID for some resources like SG"
  type        = string
}

variable "node_group_name" {
  type = string
}

variable "ssh_key_name" {
  description = "SSH key to log into EKS nodes (if needed)"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "List CIDR blocks from which traffic can flow within the ingress controller. Usually matching what the ALB is targetting"
  type        = list(string)
}

variable "ingress_port" {
  type    = number
  default = 30080
}

variable "ingressed" {
  description = "Specificy whether the node group should receive traffic towards ingress controller"
  type        = bool
}

variable "subnet_ids" {
  description = "Subnet IDs where the nodes are deployed"
  type        = list(string)
}

# Scaling rules. null means "set dynamically according to number of subnets"
variable "desired_size" {
  type     = number
  nullable = true
}

variable "max_size" {
  type     = number
  nullable = true
}

variable "min_size" {
  type     = number
  nullable = true
}

variable "max_unavailable" {
  type     = number
  nullable = true
}

variable "ami_type" {
  type = string
}

variable "aws_region" {
  description = "ie. us-west-2"
  type        = string
}

variable "ecr_repository_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "instance_types" {
  description = "List of instance types the node group can create"
  type        = list(string)
}

variable "volume_size" {
  description = "Disk size per node in GiB"
  type        = number
}

variable "volume_type" {
  description = "Volume type, eg. gp2, gp3, etc..."
  type        = string
  default     = "gp2"
}

variable "kms_arn" {
  description = "KMS key to encrypt nodes EBS volumes"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "eks_ami" {
  description = "EKS AMI identifier"
  type        = string
  default     = null # Let it select the one it wants
}

variable "cluster_ca" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_security_group_id" {
  description = "EKS cluster security group ID allowing the node to join the cluster"
  type        = string
}

variable "ssh_access_subnet_ids" {
  description = "Subnet IDs from wich SSH access to k8s nodes are allowed"
  type        = list(string)
}

variable "lb_security_groups" {
  description = "List of ALB security group IDS allowed to forward traffic to node (for ingressed only)"
  type        = list(string)
  default     = []
}

variable "eks_node_group_role_arn" {
  description = "EKS nodegroup IAM role. If passed new one is not created."
  type        = string
  default     = ""
}

variable "node_env_label" {
  type    = string
  default = "default"
}