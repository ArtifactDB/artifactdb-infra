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

## Procedures

### Migrating SealedSecret certificates

Bt default, SealedSecret controller is installed with certificates generated automatically. In the context of a platform
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

## TODO

- use custom KMS key in launch template for nodegroup
- deploy logstash to push alb logs to ELK (see k8s-tools/logstash-s3-es-logs)
- deploy fluentd to push k8s pods logs to cloudwatch (check on existing clusters)
- fix the (probable) mess with Terraform/Terragrunt variables
- how to deal with VPC (multiple, default) in general?
- use a eksautomation as a second process to secure tagging and ALB registration?
- version infra, eg. `infra.v3`, from git branch?
- support for ingress controller NGINX?
- auto-install local dependencies? like kubectl must match k8s version, but that info in from a variable
- custom eks addon install as a module (refactor)
- support for opensearch serverless with dedicated KMS per instance, collection using instance prefix, etc...
- add more nodegroup, not ingressed
- nodegroup <-> ALB circuler dep (ingress_port)
- fix ssh node access denied
- improve null resource, spec. in "post", to avoid rerunning if nothing changed
- install kubeseal (currently using https://github.com/bitnami-labs/sealed-secrets/releases/tag/v0.17.5)
- should we have that in place? https://eksctl.io/usage/kms-encryption/
