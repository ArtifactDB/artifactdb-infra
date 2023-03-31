variable "node_group_name" {
  type = string
}

variable "ingress_cidr_blocks" {
  description = "List CIDR blocks from which traffic can flow within the ingres controller. Usually matching what the ALB is targetting"
  type = list
}

variable "ingress_port" {
  type = number
  default = 30080
}

variable "ingressed" {
  description = "Specificy whether the node group should receive traffic towards ingress controller"
  type = bool
}

variable "subnet_ids" {
  description = "Subnet IDs where the nodes are deployed"
  type = list
}

# Scaling rules. null means "set dynamically according to number of subnets"
variable "desired_size" {
  type = number
  nullable = true
}

variable "max_size" {
  type = number
  nullable = true
}

variable "min_size" {
  type = number
  nullable = true
}

variable "max_unavailable" {
  type = number
  nullable = true
}

variable "ami_type" {
  type = string
}

variable "instance_types" {
  description = "List of instance types the node group can create"
  type = list
}

variable "disk_size" {
  description = "Disk size per node in GiB"
  type = number
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

