Create the secret for AWS S3 access

```
# if need regenerate sealed secret
$ kubectl create secret generic gp-chartmuseum-secret \
        --from-literal="aws-access-key=xxxx" \
        --from-literal="aws-secret-access-key=yyy" -o yam --dry-run > secrets/uat/gp-chartmuseum-secret
$ make secrets env=uat
```

