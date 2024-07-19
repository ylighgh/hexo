---
title: EMQX-安装
date: 2024-06-11 14:12:17
tags: EMQX
categories: EMQX
---

# 安装

[官方文档](https://docs.emqx.com/zh/emqx/v4.3/getting-started/install-on-k8s.html)

```bash
kubectl create ns pro-emqx
```

```bash
kubectl apply -f - <<EOF
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: emqx
  namespace: pro-emqx
  labels:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/instance: emqx
      app.kubernetes.io/name: emqx
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: emqx
        app.kubernetes.io/instance: emqx
        app.kubernetes.io/name: emqx
        version: latest
    spec:
      volumes:
        - name: pro-emqx-data
          persistentVolumeClaim:
            claimName: emqx-data
        - name: tz-config
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai
            type: ''
        - name: pro-emqx-conf
          persistentVolumeClaim:
            claimName: emqx-conf
      containers:
        - name: emqx
          image: 'harbor.axzo.cn/axzo-k8s/emqx:4.3.10'
          ports:
            - name: mqtt
              containerPort: 1883
              protocol: TCP
            - name: mqttssl
              containerPort: 8883
              protocol: TCP
            - name: ws
              containerPort: 8083
              protocol: TCP
            - name: wss
              containerPort: 8084
              protocol: TCP
            - name: dashboard
              containerPort: 18083
              protocol: TCP
            - name: ekka
              containerPort: 4370
              protocol: TCP
            - name: mgmt
              containerPort: 8081
              protocol: TCP
          envFrom:
            - configMapRef:
                name: emqx-env
          env:
            - name: EMQX_CLUSTER__DISCOVERY
              value: k8s
            - name: EMQX_CLUSTER__K8S__APP_NAME
              value: emqx
            - name: EMQX_CLUSTER__K8S__NAMESPACE
              value: pro-emqx
            - name: EMQX_CLUSTER__K8S__SERVICE_NAME
              value: emqx-headless
            - name: EMQX_NAME
              value: emqx
          resources: {}
          volumeMounts:
            - name: emqx-data
              mountPath: /opt/emqx/data
            - name: tz-config
              mountPath: /etc/localtime
            - name: emqx-conf
              mountPath: /opt/emqx/etc
          livenessProbe:
            httpGet:
              path: /status
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5
            timeoutSeconds: 2
            periodSeconds: 2
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /status
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 5
            timeoutSeconds: 2
            periodSeconds: 2
            successThreshold: 2
            failureThreshold: 3
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
          securityContext:
            runAsUser: 1000
            runAsNonRoot: true
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      serviceAccountName: emqx
      serviceAccount: emqx
      securityContext:
        runAsUser: 1000
        supplementalGroups:
          - 1000
        fsGroup: 1000
      imagePullSecrets:
        - name: harbor
      schedulerName: default-scheduler
  serviceName: emqx-headless
  podManagementPolicy: Parallel
  updateStrategy:
    type: RollingUpdate
  revisionHistoryLimit: 10
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emqx
  namespace: pro-emqx
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: emqx-env
  namespace: pro-emqx
  labels:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
data:
  EMQX_CLUSTER__K8S__ADDRESS_TYPE: hostname
  EMQX_CLUSTER__K8S__APISERVER: 'https://kubernetes.default.svc:443'
  EMQX_CLUSTER__K8S__SUFFIX: svc.cluster.local
---
metadata:
  name: emqx-nodeport
  namespace: pro-emqx
spec:
  ports:
    - name: mqtt
      protocol: TCP
      port: 1883
      targetPort: 1883
      nodePort: 30011
  selector:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
    workloadID_emqx: 'true'
  type: NodePort
  sessionAffinity: None
  externalTrafficPolicy: Cluster
apiVersion: v1
kind: Service
---
metadata:
  name: emqx
  namespace: pro-emqx
  labels:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
spec:
  ports:
    - name: mqtt
      protocol: TCP
      port: 1883
      targetPort: mqtt
    - name: mqttssl
      protocol: TCP
      port: 8883
      targetPort: mqttssl
    - name: ws
      protocol: TCP
      port: 8083
      targetPort: ws
    - name: wss
      protocol: TCP
      port: 8084
      targetPort: wss
    - name: dashboard
      protocol: TCP
      port: 18083
      targetPort: dashboard
    - name: mgmt
      protocol: TCP
      port: 8081
      targetPort: mgmt
  selector:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
  type: ClusterIP
  sessionAffinity: None
apiVersion: v1
kind: Service
---
metadata:
  name: emqx-headless
  namespace: pro-emqx
  labels:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
spec:
  ports:
    - name: mqtt
      protocol: TCP
      port: 1883
      targetPort: mqtt
    - name: mqttssl
      protocol: TCP
      port: 8883
      targetPort: mqttssl
    - name: ws
      protocol: TCP
      port: 8083
      targetPort: ws
    - name: wss
      protocol: TCP
      port: 8084
      targetPort: wss
    - name: dashboard
      protocol: TCP
      port: 18083
      targetPort: dashboard
    - name: ekka
      protocol: TCP
      port: 4370
      targetPort: ekka
    - name: mgmt
      protocol: TCP
      port: 8081
      targetPort: mgmt
  selector:
    app.kubernetes.io/instance: emqx
    app.kubernetes.io/name: emqx
  clusterIP: None
  type: ClusterIP
  sessionAffinity: None
  publishNotReadyAddresses: true
apiVersion: v1
kind: Service
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emqx
  namespace: pro-emqx
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: emqx
  namespace: pro-emqx
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - get
  - watch
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: emqx
  namespace: pro-emqx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: emqx
subjects:
- kind: ServiceAccount
  name: emqx
  namespace: pro-emqx
---

EOF
```

# 5.X版本安装

## 安装cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

## 安装 EMQX Operator
```bash
helm repo add emqx https://repos.emqx.io/charts
helm repo update
helm upgrade --install emqx-operator emqx/emqx-operator \
  --namespace emqx-operator-system \
  --create-namespace

# 确认 Operator 状态
kubectl wait --for=condition=Ready pods -l "control-plane=controller-manager" -n emqx-operator-system
```

## 安装 EMQX
```bash
kubectl apply -f - <<EOF
apiVersion: apps.emqx.io/v2beta1
kind: EMQX
metadata:
   name: open-emqx
   namespace: java-dev
spec:
   image: harbor.axzo.cn/library/emqx:5
   coreTemplate:
    spec:
      volumeClaimTemplates:
        storageClassName: sfsturbo-sc-dev
        resources:
          requests:
            storage: 10Gi
        accessModes:
          - ReadWriteMany
EOF

# 确认EMQX状态
kubectl get emqx -n java-dev


# 增加nodePort
kubectl apply -f - <<EOF
metadata:
  name: open-emqx-nodeport
  namespace: java-dev
  labels:
    apps.emqx.io/instance: open-emqx
    apps.emqx.io/managed-by: emqx-operator
spec:
  ports:
    - name: open-emqx-1883
      protocol: TCP
      port: 1883
      targetPort: 1883
    - name: open-emqx-8883
      protocol: TCP
      port: 8883
      targetPort: 8883
  selector:
    apps.emqx.io/instance: open-emqx
    apps.emqx.io/managed-by: emqx-operator
  type: NodePort
apiVersion: v1
kind: Service
EOF
```