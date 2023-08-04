# Stakater Reloader

## Usage

Allows to automatically restart deployments, statefulsets, daemonsets, when a ConfigMap or a Secret changes.
We'll use it the simple way, let the reloader discover which configmaps/secrets are used by these resources,
by annotating them with:

```
kind: Deployment
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```


To control what the reloader can touch, we also enforce a certain label to be present on ConfigMap/Secrets, eg.:

```
kind: ConfigMap
metadata:
  labels:
    reloader: enabled
```