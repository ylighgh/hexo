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