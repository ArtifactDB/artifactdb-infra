# Components

This section describes the cloud components/services required to run an ArtifactDB Platform. The configuration itself is
not described in details, the corresponding Terraform module holds that information, but some general information is
given, as well as design details when necessary.

## EKS: Kubernetes cluster

One central required service is AWS EKS, to deploy a managed Kubenetes cluster. Recent versions are supported, as the
time of this writing, Kubernetes `1.25` is the current version being targetted.

### Custom networking

The cluster itself is usually never exposed but rather deployed in private subnets, while an Application Load Balancer
(ALB, see below) is used to proxy/forward traffic to the cluster. Because each pods running in a Kubernetes cluster will
be assigned a private IP, address exhaustion is frequent, specially in the context of a corporate company where
traditional private networks (class A `10.0.0.0/8`, B `172.16.0.0/12` or C `192.168.0.0/16`) must be shared across
numerous private resources. To ovecome this limitation, non-routable subnets, [IPv4 shared address
space](https://en.wikipedia.org/wiki/IPv4_shared_address_space), are used specifically for pods. This address space
provides 100.64.0.0/16 (100.64.0.0/10 officially, but AWS CIDR blocks can't be bigger than /16), which means a total of
65536 private IPs available for pods.

These non-routable subnets are not directly used during the deployment of the cluster (otherwise worker nodes could have
an IP assigned in this space which would complexify routing in ingress traffic), a custom networking configuration is
used instead, described [here](https://aws.github.io/aws-eks-best-practices/networking/custom-networking/). This
involves creating custom ENIConfig manifests, one for each availability zone the non-routable subnets are created in, to
register and expose these subnets to the cluster, and tagging the EKS `aws-node` daemonset with a special label. This
instruct the node to use a different subnet than the one it currently is deployed on.

When a worker node joins the cluster, it must also be labelled with the ENIConfig name corresponding to the right
availability zone the node is deployed in. Without this label, pods assigned to the node will stay in `Pending` status,
because no IP address can be assigned.

### Nodegroup

This custom networking configuration impacts the way Kubernetes nodes must be created and join the cluster. To fully
automate the procedure of annotating a node, a nodegroup is created based on a Launch Template. This launch template has
multiple benefits.

- It allows to specify a custom EKS AMI image in place of the AWS provided ones, for instance to use a hardened image (a
  scenario commonly found in companies).
- Custom User-Data script can be declared. When the node starts, this custom scripts is executed. The EC2 instance
  self-discover the availability zone in which it runs, and annotate itself with the correct ENIConfig matching the
  zone. It then starts the EKS bootstrapping process and joins the cluster. Finally, if the nodegroup is declared as
  "ingressable", meaning it runs services that should be exposed through an ALB (as opposed to a batch job for instance,
  which doesn't need to exposed), it also register itself in one or more Target Groups that are connected to ALBs.

### IRSA: IAM Role for Service Account

IRSA is enabled on the cluster, to allow Kubernetes Service Account to map and assume IAM roles. This setup is
convenient when it comes to allow/restrict which cloud resources an ArtifactDB instance can access and modify (eg. full
access to its dedicated S3 buckets), without having to use IAM users (and rotate access/secret keys frequently).

## KMS: encryption at rest

A custom KMS key is created when deploying the platform. It is used for encryption-at-rest in several shared resources,
such as EBS volumes attached to worker nodes, S3 buckets collecting ALB traffic logs, etc... Note this KMS key is unique
per platform deployment, and is not reused for each ArtifactDB instance deployment, which has its own dedicated KMS key.

### Cluster-wide controllers

#### Ingress controller

An ingress controller must be deployed on the cluster, to route the traffic towards to the proper namespace and service.
[Traefik](https://traefik.io/) is the preferred one, though [NGINX](https://github.com/kubernetes/ingress-nginx) has
growing support. The ingress controller is deployed on each ingressable nodes, and is exposed through the NodePort 30080.
Note the k8s services themselves, created when deploying an ArtifactDB instance, do *not* lead to the creation of a ALB,
but rather declare ingress rules to Traefik (or NGNIX) to allow traffic exposition.

#### Secrets controller

An secret controller can be deployed to manage secrets declared in ArtifactDB instances. Sealed Secrets is currently the
only option supported. Using this controller, secrets are encrypted against that controller, meaning they can only be
unsealed in the cluster in which it was deployed. Sealed secrets information can safely be committed in git for
instance, to facilitate instance deployment.

Secrets are also stored in AWS Secret Manager, but not directly used during the deployment. The ArtifactDB Platform
uses it a the source of truth to generated sealed secrets.

## ALB: Load Balancer

An ALB is used to "capture" incoming traffic and forward it to the ingress controller. A HTTPS listener can be used by
declaring an SSL certificate, in which case the HTTP listener is configured to redirect traffic to HTTPS, instead of
forwarding traffic.

Multiple ALB can be used, for instance to declare an Internet-facing one, as well as a private one. Each have their own
Target Groups, with special tags to identify which ALB and Target Groups must be used when the "ingressable" nodes
self-register themselves when booting (see above). Target Groups are configured to forward traffic to port 30080, the
same port used by Traeffik.

## Opensearch cluster

A shared Opensearch (or Elasticsearch cluster) is deployed within the platform. While an instance could have its own
dedicated cluster, a shared instance is recommended to reduce the cost. More, indices produced by ArtifactDB instances
are usually small enough to allow sharing resources, yet maintaining a good performance.

ElasticSearch 7.4 and Opensearch 1.3 are currently supported, though Opensearch >2.3 is being targetted. In the context
of AWS and a shared indexing engine, Opensearch provides per-index permissions, meaning it's possible to restrict an
instance to a set of specific indices assigned during its deployement, while restricting it from accessing other
instances' indices.

Following one important principle in ArtifactDB, the whole content of an index (or more) in Opensearch can be fully
restored from the metadata files found on S3. It is strictly a secondary storage.

## RDS: PostgreSQL

ArtifactDB instances use PostgreSQL to provision project ID and versions in a transactional way. There's no actual data,
or metadata stored in the database, only identifiers. The requirements fare pretty low, a small instance is enough,
deployed in multiple AZ for production to improve uptime and reliability.

Following the same principle explained above, the whole table content can be restored from S3 itself, by listing all
project IDs and their respective versions. It is also a secondary storage.  be fully restored from the metadata files
found on S3. It is strictly a secondary storage.

## Optional components

### FluentBit and Cloudwatch agent

Both these components can be used to populate Cloudwatch log groups to give visibility and traceability on the whole
platform. Cloudwatch agents log information about the cluster itself (nodes, etc...) while FluentBit works at the pods
level, logging their stdout/stderr.

### Logstash

[Logstash](https://www.elastic.co/logstash) is one major component of the ELK stack (Elasticsearch, Logstash, Kibana)
used to ingest logs and make them search in [Kibana](https://www.elastic.co/kibana). By default when setting up an ALB
in the platform, logs are stored in a S3 bucket. Deploying the Logstash component allows to ingest these logs from S3
and index them in the Elasticsearch/Opensearch cluster.

### Cerebro

[Cerebro](https://github.com/lmenezes/cerebro) is a UI on top of Elasticsearch, conveniently providing an adminitrative
overview of a cluster, operations to manipulate global and index settings, visualize index mappings, and query indexed
data. The access must be restricted to admins only, protected by user/passwords.

### Chartmuseum

[Chartmuseum](https://chartmuseum.com/) is a Helm Charts repository servers. If ArtifactDB instances are to be deployed
from charts stored as tarballs accessible from such a server, a instance of Chartmuseum can be deployed within the
platform for that purpose.

### Stakater Reloader

[Stakater Reloader](https://github.com/stakater/Reloader) is a convenient Kubernetes operator used to detect changes on
ConfigMaps and Secrets objects and automatically restart Deployments and StatefulSets. ArtifactDB deployment code (Helm
Chart) can use this reloader to automatically maintain latest *active* configuration or secrets (eg. rotation). Without
such a reloader, changes may be not become active and a manual restart would be necessary.

### Synthetic Canaries

To perform basic monitoring and make sure ArtifactDB instances are reachable from outside of the cloud VPC, [Synthetic
Canaries](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html) can be
deployed, along with a list of URLs to check on a periodic schedule. Checks are very simple, but depending on what is
being tested behind the URLs, lots of connectivity can be verified and issues spotted when things go wrong.
Traditionally, the endpoint `GET /status` is used in ArtifactDB instances, checking Elasticsearch and Celery backend
connectivity.

### Bastion and SSH keys

In some restricted environment, some resources like the EKS nodes and databases, can only be accessed from within a VPC
and from some specific subnets. This is to protect access from outside. Yet the administration of the platform can still
require access to these resources. In such scenario and "Bastion" instance can be created with dedicated SSH keys,
deployed on "connectivity" subnets allowing access from outside, providing a "hop" into the VPC.

## Post-deployment

Once the ArtifactDB Platform is deployed, Terraform outputs are captured and stored in a ConfigMap object in Kubernetes.
This object is later used by Olympus, the self-service component of the platform, in order to discover specific
parameters of the platform itself, like its version, 


