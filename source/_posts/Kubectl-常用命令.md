---
title: Kubectl-常用命令
date: 2024-06-11 14:12:17
tags: Kubectl
categories: Kubectl
---

# 常用命令

## 创建证书
```bash
kubectl create secret tls api-cdht-https --cert api-cdht.cdhtgycs.cn.pem --key api-cdht.cdhtgycs.cn.key -n prod
```

## 扩缩容
```bash
kubectl scale deployment foo --replicas=0
```

## 创建ServiceAccount并绑定Secret
```bash
kubectl apply -f <<EOF -
apiVersion: v1
automountServiceAccountToken: true
kind: ServiceAccount
metadata:
  name: jenkins-blue
  namespace: kube-ops
secrets:
- name: jenkins-blue
---
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-blue
  namespace: kube-ops
  annotations:
    kubernetes.io/service-account.name: "jenkins-blue"
type: kubernetes.io/service-account-token
EOF
```