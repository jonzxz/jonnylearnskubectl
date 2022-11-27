#!/bin/bash

## Prequisite installations

## Script assumes docker is already installed and user is added to Docker group
# https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository

## Install kubectl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# rm kubectl
# kubectl --version

## Install minikube
# curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# sudo install minikube-linux-amd64 /usr/local/bin/minikube
# rm minikube*
# minikube version

## Minikube start up - script assumes minikube is already started
# minikube start

## Install helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
# rm get_helm.sh

## Add Prometheus repo from helm
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

## End install

## Startup

## Start Prometheus and portforward to 9090
echo "Launching Prometheus -- this will take awhile - port forwarding executed in background"
helm install prometheus-community/prometheus --generate-name
export POD_NAME=$(kubectl get pods --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready pod $POD_NAME
$(kubectl --namespace default port-forward $POD_NAME 9090)&

echo "Mount minikube volume"
# Mount local directory as minikube volume, to be mounted into containers
$(minikube mount ./html:/host/www)&

echo "Spinning up nginx and MySQL"
# Spin up other resources in kube
kubectl apply -f nginx.yaml,mysql.yaml

echo "Enabling port forwarding for nginx"
# Check for pod readiness before enabling port forwarding for nginx
export SERVICE_NAME=$(kubectl get svc --namespace default -l "run=nginx-counter" -o jsonpath="{.items[0].metadata.name}")
export POD_NAME=$(kubectl get pods --namespace default -l "run=nginx-counter" -o jsonpath="{.items[0].metadata.name}")
kubectl wait --for=condition=ready pod $POD_NAME
kubectl port-forward service/$SERVICE_NAME 8080:80

## End startup

## Exits - not to be executed in this script, for reference to wind down

## Dismount minikube volume
## Shell termination should kill off mount
## kill off mount to exit if shell termination does not work
# sudo kill $(ps -C "minikube mount" -o pid=)

## Finally - wind down deployment and Prometheus
# kubectl delete -f nginx.yaml,mysql.yaml
# Release helm
# helm delete $(helm list --filter '^prometheus*' -q)

## End exits