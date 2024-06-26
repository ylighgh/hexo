---
title: Linux-常用Shell命令
date: 2024-06-11 14:12:17
tags: Linux
categories: Linux
---

# 批量删除指定状态的pods
```bash
kubectl --kubeconfig gxq-config get pods -A|grep Evicted|awk '{print $1" "$2}'|while read LINE
do
    namespace=`echo $LINE|awk '{print $1}'`
    pod=`echo $LINE|awk '{print $2}'`
    kubectl --kubeconfig gxq-config delete pod -n $namespace $pod
done
```