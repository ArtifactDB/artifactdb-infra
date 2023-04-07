# Artifactdb Infrastructure

This repository contains Terraform scripts to deploy foundational infrastructure to deploy the ArtifactDB Platform.
It's currently targetting the AWS cloud:

- a Kubernetes cluster, EKS, with:
  - an ingress controller (Traefik, NGINX)
  - SealedSecret controller
  - Karpenter (optional) for fast auto-scaling
- an Application Load Balancer with targer groups
- an OpenSearch or Elasticsearch cluster
- all the necessary roles and policies

This infrastructure is a foundation to then deploy ArtifactDB instances and other systems.


## Dependencies

### Terraform and Terragrunt

Deployment is based on Terragrunt, a Terraform wrapper used to make Terraform a little bit less painful to play with.
See install instruction here: https://terragrunt.gruntwork.io/docs/getting-started/quick-start/


### AWS CLI

From https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html.
A recent version is required, >= 1.27 from the test I did (latest version are >2.x), in order
to produce correct EKS authentication in the kube config

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### kubectl

Must match the Kubernetes version, see https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html.

```
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.7/2023-03-17/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
hash -r
```

### jq

To process some output from kubectl.

```
apt install jq
```


## TODO

- use custom KMS key in launch template for nodegroup
- fix the (probable) mess with Terraform/Terragrunt variables
- how to deal with VPC (multiple, default) in general?
- use a eksautomation as a second process to secure tagging and ALB registration?
- version infra, eg. `infra.v3`, from git branch?
- support for ingress controller NGINX?
- auto-install local dependencies? like kubectl must match k8s version, but that info in from a variable
- custom eks addon install as a module (refactor)
- support for opensearch serverless with dedicated KMS per instance, collection using instance prefix, etc...



