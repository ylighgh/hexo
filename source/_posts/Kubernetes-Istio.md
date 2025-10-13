---
title: Kubernetes-Istio-安装
date: 2025-10-13 22:44:21
tags: Kubernetes
categories: Kubernetes
---

# Download
```
curl -L https://istio.io/downloadIstio | sh -

cd istio-1.27.1

export PATH=$PWD/bin:$PATH
```

# Install
```bash
# 1. Install Istio using the demo profile, without any gateways:
istioctl install -f samples/bookinfo/demo-profile-no-gateways.yaml -y

# 2. Add a namespace label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later:
kubectl label namespace default istio-injection=enabled
```

# Install the Kubernetes Gateway API CRDs
```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; }
```


# Deploy the sample application
```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```


# Verify
```bash
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```


# Open the application to outside traffic
```bash
# Create a Kubernetes Gateway for the Bookinfo application:
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml

# Change the service type to ClusterIP by annotating the gateway:
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default

# To check the status of the gateway, run:
kubectl get gateway

```

