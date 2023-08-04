#!/bin/bash

# Update the kubeconfig
aws eks update-kubeconfig --name "$1" --profile "$2" --region "$3"

# Fetch the existing roles
existing_roles=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}')

# Append the new roles
echo -e "${existing_roles}\n$4" >> mapRoles.txt

# Prepare the payload for the patch command
mapRoles_payload=$(jq -n --arg mapRoles "$(cat mapRoles.txt | sed 's/\\n/\\\\n/g' | sed 's/\\t/\\\\t/g')" '{"data": {"mapRoles": $mapRoles}}')

# Write the payload to a JSON file
echo "$mapRoles_payload" > mapRolesPayload.json

# Patch the aws-auth ConfigMap
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat mapRolesPayload.json)"

# Clean up
rm mapRolesPayload.json mapRoles.txt
