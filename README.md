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

Deployment is based on Terragrunt, a Terraform wrapper used to make Terraform a little bit less painful to play with.
See install instruction here: https://terragrunt.gruntwork.io/docs/getting-started/quick-start/

It also requires
- jq: `apt install jq`


TODO:
- use custom KMS key in launch template for nodegroup
- fix the (probable) mess with Terraform/Terragrunt variables
- how to deal with VPC (multiple, default) in general?
- use a eksautomation as a second process to secure tagging and ALB registration?



