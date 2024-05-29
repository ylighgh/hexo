---
title: Kubernetes-EndPoint使用示例
date: 2024-05-29 13:29:39
tags: Kubernetes
categories: Kubernetes
---

# 创建service
![](/images/k8s/endpoint.png)

```bash
kubect apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: axzo-test-rds-master
  namespace: test
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  sessionAffinity: None
  type: ClusterIP
EOF
```

# 创建Endpoint
```bash
kubect apply -f - <<EOF
apiVersion: v1
kind: Endpoints
metadata:
  name: axzo-test-rds-master
  namespace: test
subsets:
- addresses:
  - ip: 172.16.2.143
  ports:
  - port: 3306
    protocol: TCP
EOF
```