resource "null_resource" "enable_custom_cni" {
triggers = {
    always_run = timestamp()
}
depends_on = [aws_eks_cluster.eks_cluster]
provisioner "local-exec" {
    on_failure  = fail
    when = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[32m Testing Network Connectivity ${aws_eks_cluster.eks_cluster.name}...should see port 443/tcp open  https\x1B[0m"
        ./test.sh ${aws_eks_cluster.eks_cluster.name}
        echo -e "\x1B[32m Checking Authorization ${aws_eks_cluster.eks_cluster.name}...should see Server Version: v1.18.xxx \x1B[0m"
        aws eks update-kubeconfig --name "${aws_eks_cluster.eks_cluster.name}"
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

