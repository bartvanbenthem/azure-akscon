#!/bin/bash

# set the subscription
az account set -s $SUBSCR 
az account show

# DYNAMIC ENV VARIABLES
export ACCOUNT="azdevops-svconnection"
export RESOURCEGROUP=$(az aks list --query [0].resourceGroup -o tsv)
export CLUSTER=$(az aks list --query [0].name -o tsv)
export APIADDRESS=$(az aks show --resource-group $RESOURCEGROUP --name $CLUSTER --query fqdn -o tsv)

# create and set context
az aks get-credentials --resource-group $RESOURCEGROUP --name $CLUSTER --admin --overwrite-existing 
kubectl config get-contexts

# create service account azure devops
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $ACCOUNT
  namespace: $NAMESPACE
EOF

# create rolebinding azure devops
kubectl apply -f - <<EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: azdevops-owner-binding
  namespace: $NAMESPACE
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  namespace: $NAMESPACE
  name: $ACCOUNT
EOF

# load secret in to memmory
svcaccount=$(kubectl get secret -n $NAMESPACE | grep $ACCOUNT | awk '{print $1}')
secret=$(kubectl get secret $svcaccount --namespace $NAMESPACE -o yaml)

# print values regarding service connection fields
echo "########## AZURE-DEVOPS-KUBERNETES-SERVICE-CONNECTION ############"
echo "use the following information for the service connection fields"

echo "Connection name: $NAMESPACE-$ACCOUNT"
echo "Server URL: $APIADDRESS"
echo "Secret: " && echo $secret