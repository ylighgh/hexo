---
title: Kubernetes-持久化存储
date: 2024-05-29 22:26:00
tags: Kubernetes
categories: Kubernetes
---

# HostPath

# EmptyDir

# NFS

## 安装NFS

```bash
yum -y install nfs-utils
```

## 启动NFS
```bash
systemctl start nfs-server
systemctl enable nfs-server
```

## 创建共享目录
```bash
mkdir -p /data/nfs/ro
mkdir -p /data/nfs/rw
```

## 修改配置
```bash
cat <<EOF> /etc/exports
/data/nfs/rw 192.168.10.0/24(rw,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)
/data/nfs/ro 192.168.10.0/24(ro,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)
EOF

exportfs -r
systemctl restart nfs-server
```

## 挂载
```bash
mkdir -p /mnt/nfs/rw
mount -t nfs 192.168.10.245:/data/nfs/rw /mnt/nfs/rw/
```

# PV/PVC

