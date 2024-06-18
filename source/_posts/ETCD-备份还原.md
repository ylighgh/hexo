---
title: ETCD-数据备份与恢复
date: 2024-06-11 14:12:17
tags: ETCD
categories: ETCD
---

# 备份
```bash
ETCDCTL_API=3 etcdctl snapshot save snapshot.db
ETCDCTL_API=3 etcdctl  snapshot status snapshot.db -w=table
```
# 还原

在 `containers` 同级增加以下yaml 同时挂载pvc进去

```yaml
      initContainers:
        - name: data-restore
          image: 'harbor.axzo.cn/ops/etcd:3.5.4-debian-11-r14'
          command:
            - /bin/bash
          args:
            - '-c'
            - 'rm -rf /bitnami/etcd/data/* && etcdctl snapshot restore /restore-volume/20240617_030015_apisix_snapshot.db --name $(MY_POD_NAME) --data-dir=/bitnami/etcd/data --initial-cluster pro-apisix-etcd-0=http://pro-apisix-etcd-0.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-1=http://pro-apisix-etcd-1.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380,pro-apisix-etcd-2=http://pro-apisix-etcd-2.pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380 --initial-cluster-token etcd-cluster-k8s --initial-advertise-peer-urls http://$(MY_POD_NAME).pro-apisix-etcd-headless.pro-apisix.svc.cluster.local:2380'
          env:
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
          resources: {}
          volumeMounts:
            - name: data
              mountPath: /bitnami/etcd
            - name: restore-volume
              mountPath: /restore-volume
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
```