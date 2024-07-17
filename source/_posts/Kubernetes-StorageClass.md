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


### 华为云创建SFS
```bash
kubectl apply -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: sfsturbo-k8s-ops
provisioner: everest-csi-provisioner
parameters:
  csi.storage.k8s.io/csi-driver-name: sfsturbo.csi.everest.io
  csi.storage.k8s.io/fstype: nfs
  everest.io/archive-on-delete: 'true'
  everest.io/share-expand-type: bandwidth
  everest.io/share-export-location: xxxx.sfsturbo.internal:/k8s-ops-sc/
  everest.io/share-source: sfs-turbo
  everest.io/share-volume-type: STANDARD
  everest.io/volume-as: subpath
  everest.io/volume-id: xxxxx
reclaimPolicy: Delete
mountOptions:
  - nolock=false
volumeBindingMode: Immediate
EOF
```