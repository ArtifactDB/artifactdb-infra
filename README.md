# Artifactdb Infrastructure

This repository contains Terraform scripts to deploy foundational infrastructure to deploy the ArtifactDB Platform.
It's currently targetting the AWS cloud:

- a Kubernetes cluster, EKS, with:
  - an ingress controller (Traefik, NGINX)
  - SealedSecret controller
  - fluent-bit for storing infra level logs
  - logstash for storing application level logs
  - stakater reloader 
  - NOT YET IMPLEMENTED Karpenter (optional) for fast auto-scaling
- an Application Load Balancer with target groups
- an OpenSearch or Elasticsearch cluster
- all the necessary roles and policies

This infrastructure is a foundation to then deploy ArtifactDB instances and other systems.


## Dependencies

### Auto-installation

Use ``` prepare_local_env.sh``` to install all dependencies needed for local deployment.

### Terraform and Terragrunt

Deployment is based on Terragrunt, a Terraform wrapper used to make Terraform a little bit less painful to play with.
See install instruction here: https://terragrunt.gruntwork.io/docs/getting-started/quick-start/

## Procedures

### Migrating SealedSecret certificates

By default, SealedSecret controller is installed with certificates generated automatically. In the context of a platform
upgrade, deploying sealed secrets encrypted with the old controller (old platform) will fail with an error on the
object: `Failed to unseal: no key could decrypt secret`. One option is the re-encrypt the secrets using the controller
and its new certificate but it brings complexity in the migration process. The other option is to replace the new
certificates with the old ones, from the old platform.

SealedSecret rotates keys every 30 days by default, which complifies the migration: all used keys need to be copied
over. See https://ismailyenigul.medium.com/take-backup-of-all-sealed-secrets-keys-or-re-encrypt-regularly-297367b3443.

Pointing to old cluster:
```
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o yaml | kubectl neat  > allsealkeys.yml
```

Now pointing to new cluster and restore:
```
kubectl -n kube-system apply -f allsealkeys.yml
```

Restart the controller so it can find the restored keys (delete the pod, it gets deployed again). In the logs we can
see:
```│ 2023/05/25 20:21:31 Searching for existing private keys                                                                                                                                                                                                                                                                                                                                                                                 │
2023/05/25 20:21:31 ----- sealed-secrets-key9pjzj
2023/05/25 20:21:31 ----- sealed-secrets-key2jmx9
2023/05/25 20:21:31 ----- sealed-secrets-key5hbbm
2023/05/25 20:21:31 ----- sealed-secrets-key5tmjn
2023/05/25 20:21:31 ----- sealed-secrets-key8ccdq
2023/05/25 20:21:31 ----- sealed-secrets-key5c4gg
2023/05/25 20:21:31 ----- sealed-secrets-keycp2km
2023/05/25 20:21:31 ----- sealed-secrets-keyd6lb2
2023/05/25 20:21:31 ----- sealed-secrets-keyd7h9x
2023/05/25 20:21:31 ----- sealed-secrets-keydwhxs
2023/05/25 20:21:31 ----- sealed-secrets-keyfrmd6
2023/05/25 20:21:31 ----- sealed-secrets-keyglq6r
2023/05/25 20:21:31 ----- sealed-secrets-keyh4wgz
2023/05/25 20:21:31 ----- sealed-secrets-keyhclzv
2023/05/25 20:21:31 ----- sealed-secrets-keyjjmpn
2023/05/25 20:21:31 ----- sealed-secrets-keymblzl
2023/05/25 20:21:31 ----- sealed-secrets-keyrfz4m
2023/05/25 20:21:31 ----- sealed-secrets-keyvss66
2023/05/25 20:21:31 ----- sealed-secrets-keyzsfnf
```

Sealed secrets are now properly unsealed, describing a sealed secret object, we see: `SealedSecret unsealed
successfully`.

## Modules description  
  
1) **push_images_ecr**  
- Used for populating AWS ECR. Consists of two submodules:  
	- docker_build_push_ecr  
		- Builds docker images and pushes it to AWS ECR 
	- docker_pull_push_ecr  
		- Pulls opensource image and pushes it to private AWS ECR  
2) **post**
- Creation of k8s secret with all terraform outputs with explicitly set to not include bastion module outputs as these are not needed.
3) **bastion**
- EC2 used as ssh entrypoint to k8s nodes. Bastion is deployed in the same VPC as EKS nodes.
4) **ssh**
- Creates ssh key which is used for bastion and k8s nodes. Key is saved locally.
### Tips and tricks worth mentioning

- For creation of SSM secret this snippet can be used: 
```
module "aws_ssm_secrets" {
  source = "../ssm_secrets"

  secrets = {
    "/gprn/${var.environment}/platform/${var.platform_id}/secret/${local.module}" = jsonencode({
      "secret_name" = secret_value
    })
  }

  kms_key_arn = var.kms_arn
  tags = {
    gprn = "gprn:${var.environment}:platform:${var.platform_id}:secret:${local.module}"
    env  = var.environment
  }
}
```
- EKS module sets:
```
kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone
kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
```
which allows every new k8s node to be picked up by AWS VPC CNI.

- Synthetics canaries has ``` timeout_in_seconds = 30 ```. 
That timeout needs to be increased when number of endpoints to test by canary will increase. For 5 endpoints 30sec is more than enough.
## TODO

- use custom KMS key in launch template for nodegroup
- version infra, eg. `infra.v3`, from git branch?
- support for ingress controller NGINX?
- auto-install local dependencies? like kubectl must match k8s version, but that info in from a variable
- custom eks addon install as a module (refactor)
- support for opensearch serverless with dedicated KMS per instance, collection using instance prefix, etc...
- nodegroup <-> ALB circuler dep (ingress_port)
- install kubeseal (currently using https://github.com/bitnami-labs/sealed-secrets/releases/tag/v0.17.5)
- should we have that in place? https://eksctl.io/usage/kms-encryption/
