MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
# proceed to bootstrap
B64_CLUSTER_CA=${cluster_ca}
API_SERVER_URL=${cluster_endpoint}
K8S_CLUSTER_DNS_IP=172.20.0.10
/etc/eks/bootstrap.sh ${cluster_name} --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup-image=${eks_ami},eks.amazonaws.com/capacityType=ON_DEMAND,eks.amazonaws.com/nodegroup=${node_group_name}' --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --dns-cluster-ip $K8S_CLUSTER_DNS_IP --use-max-pods false

# self-register ALB TG
if [ "X${ingressed}" != "X" ]
then
    instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
    # there can be multiple Target Groups, find them using custom ta
    for tg_arn in `aws resourcegroupstaggingapi get-resources --resource-type-filters elasticloadbalancing:targetgroup --tag-filters Key=OwnedBy,Values=${cluster_name} --tag-filters Key=ArtifactDBIngress,Values=true --query ResourceTagMappingList[].ResourceARN --output text`
    do
        echo "Self-registering instance $instance_id to ALB target group $tg_arn"
        aws elbv2 register-targets --target-group-arn $tg_arn --targets Id=$instance_id
    done
else
    echo "Node not ingressable, no self-registration to ALB"
fi

--//--

