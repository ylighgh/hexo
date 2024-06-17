---
title: APISIX-数据备份与恢复
date: 2024-06-11 14:12:17
tags: APISIX
categories: APISIX
---

# 备份
```bash
ETCDCTL_API=3 etcdctl snapshot save snapshot.db
ETCDCTL_API=3 etcdctl  snapshot status snapshot.db -w=table
```
# 还原

## 将备份数据放进etcd容器
```bash
kubectl -n pro-apisix cp snapshot.db pro-apisix-etcd-0:/tmp/
kubectl -n pro-apisix cp snapshot.db pro-apisix-etcd-1:/tmp/
kubectl -n pro-apisix cp snapshot.db pro-apisix-etcd-2:/tmp/
```

## pro-apisix-etcd-0
```bash
kubectl exec -it -n pro-apisix pro-apisix-etcd-0 -- bash

cd /tmp

rm -rf /bitnami/etcd/data/*

ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
--name pro-apisix-etcd-0 \
--data-dir="/bitnami/etcd/data" \
--initial-cluster pro-apisix-etcd-0=http://pro-apisix-etcd-0.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-1=http://pro-apisix-etcd-1.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-2=http://pro-apisix-etcd-2.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380 \
--initial-advertise-peer-urls http://pro-apisix-etcd-0.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380
```

## pro-apisix-etcd-1
```bash
kubectl exec -it -n pro-apisix pro-apisix-etcd-1 -- bash

cd /tmp

rm -rf /bitnami/etcd/data/*

ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
--name pro-apisix-etcd-1 \
--data-dir="/bitnami/etcd/data" \
--initial-cluster pro-apisix-etcd-0=http://pro-apisix-etcd-0.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-1=http://pro-apisix-etcd-1.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-2=http://pro-apisix-etcd-2.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380 \
--initial-advertise-peer-urls http://pro-apisix-etcd-1.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380
```

## pro-apisix-etcd-2
```bash
kubectl exec -it -n pro-apisix pro-apisix-etcd-2 -- bash

cd /tmp

rm -rf /bitnami/etcd/data/*

ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
--name pro-apisix-etcd-2 \
--data-dir="/bitnami/etcd/data" \
--initial-cluster pro-apisix-etcd-0=http://pro-apisix-etcd-0.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-1=http://pro-apisix-etcd-1.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-2=http://pro-apisix-etcd-2.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380 \
--initial-advertise-peer-urls http://pro-apisix-etcd-2.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380
```