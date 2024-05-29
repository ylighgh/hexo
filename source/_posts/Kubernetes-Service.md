---
title: Kubernetes-Service/Ingress
date: 2024-05-29 22:26:00
tags: Kubernetes
categories: Kubernetes
---

# Service

## 概念

Kubernetes 中 Service 是 将运行在一个或一组 Pod 上的网络应用程序公开为网络服务的方法。

## 类型

- ClusterIP
- ExternalName: 返回定义的CNAME别名，可以配置为域名
- NodePort: 所有node上绑定一个端口 在任意一个节点+端口号都能访问
- LoadBalancer: 负载均衡器

# Ingress

## 概念

Ingress 是对集群中服务的外部访问进行管理的 API 对象，典型的访问方式是 HTTP。

Ingress 可以提供负载均衡、SSL 终结和基于名称的虚拟托管。

## 安装

### 添加Helm仓库

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

### 解压
```bash
helm pull ingress-nginx/ingress-nginx
tar xf ingress-nginx-4.10.1.tgz
```

### 安装
```bash
cd ingress-nginx
helm install ingress-nginx --create-namespace -n ingress-nginx .
```
