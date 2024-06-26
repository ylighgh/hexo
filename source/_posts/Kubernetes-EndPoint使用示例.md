---
title: Kubernetes-EndPoint使用示例
date: 2024-05-29 13:29:39
tags: Kubernetes
categories: Kubernetes
---

# 创建service
![](/images/k8s/endpoint.png)

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: axzo-prd-rds-master
  namespace: prod
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: axzo-prd-rds-master
  namespace: prod
subsets:
- addresses:
  - ip: 192.168.1.99
  ports:
  - port: 3306
    protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: axzo-prd-rds-readonly
  namespace: prod
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: axzo-prd-rds-readonly
  namespace: prod
subsets:
- addresses:
  - ip: 192.168.1.62
  ports:
  - port: 3306
    protocol: TCP    
EOF
```