---
title: Kubernetes-StorageClass
date: 2024-06-25 22:26:00
tags: Kubernetes
categories: Kubernetes
---

# StorageClass

## 概念



## 类型

### NFS

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.10.237 \
    --set nfs.path=/ifs/kubernetes/
```

**设置为默认存储类**
```bash
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' 
```