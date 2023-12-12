.PHONY: default

define HELP

NAME
	simple-deployment - Simple Makefile to build some random k8s stuff on a k3d

SYNOPSIS
	make create-cluster - Creates k3d cluster with Traefik disabled
	make install-nginx - Installs ingress-nginx Helm Chart

endef

export HELP

default:
	@echo "$$HELP"

create-cluster:
	k3d cluster create \
  	-p "80:80@loadbalancer" \
  	--agents 3 --k3s-arg="--disable=traefik@server:0"

delete-cluster:
	k3d cluster delete

install-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade --install ingress-nginx \
		-f ./ingress-nginx/values.yaml -f ./ingress-nginx/custom.yaml \
  	--create-namespace -n ingress-nginx \
		ingress-nginx/ingress-nginx --version 4.8.4

deploy-httpd:
	kubectl apply -f httpd/deployment.yaml

delete-httpd:
	kubectl delete -f httpd/deployment.yaml

deploy-yeasyweb:
	kubectl apply -f yeasyweb/deployment.yaml

delete-yeasyweb:
	kubectl delete -f yeasyweb/deployment.yaml
