#!/bin/bash

# this script is intented to run when the kubectl has access to the cluster
# in order to run some post set up stuff

kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=/home/gspanos/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson

# nginx ingress controller
kubectl create ns ingress-nginx
helm install my-release oci://ghcr.io/nginxinc/charts/nginx-ingress --version 1.2.2 --namespace ingress-nginx


# metallb
helm repo add metallb https://metallb.github.io/metallb
kubectl create namespace metallb-system
helm install metallb metallb/metallb --namespace metallb-system --create-namespace
kubectl apply -f metallb.yml

# cert manager

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0 \
  --set crds.enabled=true

kubectl apply -f issuer.yml 

# hetzner

kubectl apply -f hetzner.yml
helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud
helm install hccm hcloud/hcloud-cloud-controller-manager -n kube-system

kubectl -n ingress-nginx annotate services ingress-nginx-controller \
  load-balancer.hetzner.cloud/name="k8s-lb" \
  load-balancer.hetzner.cloud/location="nbg1" \
  load-balancer.hetzner.cloud/use-private-ip="true" \
  load-balancer.hetzner.cloud/uses-proxyprotocol="true