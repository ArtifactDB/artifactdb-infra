# Introduction

ArtifactDB is a cloud-based data management solution, used to securely store arbitrary data along with searchable
metadata. The ArtifactDB Platform allows to create and manage ArtifactDB instances, as a self-service. This document
describes the cloud foundations on AWS required to deploy the third iteration[^1] of the platform.

The main components behind that platform are:

- a Kubernetes cluster: all APIs are packaged as Helm chart and deployed within a dedicated Kubernetes cluster.
- cluster-wide controllers, such as an ingress controller, and secrets manager controller.
- a Application Load Balancer as the main entry point, forwarding traffic to that Kubernetes cluster
- an Elasticsearch, or OpenSearch cluster, usually shared across instances, handling metadata indexing.

Deployments details are explained in the next section. Implementation is based on Terraform modules. The last section
shows an example of deployment in a public AWS cloud account, using Terragrunt.

Once the platform is operational, ArtifactDB instances can automatically be registered and deployed, using Olympus, the
self-service component of the platform.


[^1]: What about the first and second iteration? There's no official description... The first iteration is a manual
  deployment. The second iteration brings some level of automation, while this third iteration increases reliability,
  is more generic, and push the automation cursor further up.
