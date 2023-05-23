resource "null_resource" "enable_custom_cni" {
  triggers = {
    id = aws_eks_cluster.eks_cluster.arn
  }
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            set -e
            echo -e "\x1B[32m Testing Network Connectivity ${aws_eks_cluster.eks_cluster.name}...should see port 443/tcp open  https\x1B[0m"
            echo -e "\x1B[32m Checking Authorization ${aws_eks_cluster.eks_cluster.name}...should see Server Version: v1.18.xxx \x1B[0m"
            aws eks update-kubeconfig --name "${aws_eks_cluster.eks_cluster.name}" --profile ${var.aws_profile} --region ${var.aws_region}
            # this has auto-switched to new cluster context
            echo "************************************************************************************"
            # set custom networking for the CNI
            kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
            # quick look to see if it's now set
            kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment | grep CUSTOM
            echo "************************************************************************************"
EOT
  }
}

# generate ENIConfig per AZ
resource "null_resource" "eniconfig" {
  triggers = {
    id = aws_eks_cluster.eks_cluster.arn
  }
  for_each   = toset(var.non_routable_subnets)
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            set -e
            echo "Generating ENIConfig manifests"
            # Extract AZ from each subnet
            az=`aws ec2 describe-subnets --subnet-ids "${each.value}" --profile ${var.aws_profile} --region ${var.aws_region} | jq -r .Subnets[0].AvailabilityZone`
            echo Subnet "${each.value}", availability zone: $az
            cat <<EOF > "${path.module}/$az-eniconfig-2.yaml"

# Generated for AZ $az
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: $az
spec:
  securityGroups:
  - "${aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id}"
  subnet: "${each.value}"

EOF
            echo Applying ENIConfig manifest "${path.module}/$az-eniconfig.yaml"
            kubectl apply -f "${path.module}/$az-eniconfig-2.yaml"
            echo "************************************************************************************"
EOT
  }
}

resource "null_resource" "eni_config_label_def" {
  triggers = {
    id = aws_eks_cluster.eks_cluster.arn
  }
  depends_on = [aws_eks_cluster.eks_cluster, null_resource.eniconfig]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
            set -e
            echo -e "\x1B[32m Testing Network Connectivity ${aws_eks_cluster.eks_cluster.name}...should see port 443/tcp open  https\x1B[0m"
            echo -e "\x1B[32m Checking Authorization ${aws_eks_cluster.eks_cluster.name}...should see Server Version: v1.18.xxx \x1B[0m"
            aws eks update-kubeconfig --name "${aws_eks_cluster.eks_cluster.name}" --profile ${var.aws_profile} --region ${var.aws_region}
            # this has auto-switched to new cluster context
            echo "************************************************************************************"
            kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
            echo "************************************************************************************"
EOT
  }
}

