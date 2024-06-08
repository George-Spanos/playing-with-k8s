#!/bin/bash

# this script is intented to run when the kubectl has access to the cluster
# in order to run some post set up stuff

# docker registry secret. Remember to create this for every namespace that neeeds it
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=/home/gspanos/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson



# metallb
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
kubectl apply -f metallb.yml

# nginx ingress controller
kubectl create ns ingress-nginx
helm install nginx-controller --namespace ingress-nginx --create-namespace ./nginx-ingress

# cert managerz
helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0 \
  --set crds.enabled=true
