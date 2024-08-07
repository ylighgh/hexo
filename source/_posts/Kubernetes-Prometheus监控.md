---
title: Kubernetes-Prometheus监控
date: 2024-08-07 23:42:05
tags: Prometheus
categories: Kubernetes
---
# Prometheus

Thanos + Prometheus 高可用

# 创建namespace

```bash
kubectl create ns thanos
```

# 安装Prometheus
```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: thanos
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: thanos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: thanos
data:
  prometheus.yml: |
    global:
      scrape_interval:     15s 
      evaluation_interval: 15s
      external_labels:
          k8s_cluster: a-cluster
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
        - targets: ['localhost:9090']
      - job_name: 'node-exporter'
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - source_labels: [__address__]
          regex: '(.*):10250'
          replacement: '${1}:9100'
          target_label: __address__
          action: replace
        - source_labels: [__address__]
          target_label: instance
        - source_labels: [ __address__]
          regex: (.*):(.*)
          replacement: ${1}
          target_label: node
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometueus-data
  namespace: thanos
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-client
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: prometheus
  name: prometheus
  namespace: thanos
spec:
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - args:
            - sidecar
            - '--tsdb.path=/prometheus'
            - '--prometheus.url=http://localhost:9090'
            - '--http-address=0.0.0.0:19191'
            - '--grpc-address=0.0.0.0:19091'
          image: 'harbor.axzo.cn/library/thanos:latest'
          imagePullPolicy: IfNotPresent
          name: thanos
          ports:
            - containerPort: 19191
              protocol: TCP
            - containerPort: 19091
              protocol: TCP
          resources:
            limits:
              cpu: '1'
              memory: 1Gi
            requests:
              cpu: 500m
              memory: 1Gi
          volumeMounts:
            - mountPath: /prometheus
              name: prometueus-data
        - args:
            - '--config.file=/etc/prometheus/prometheus.yml'
            - '--storage.tsdb.path=/prometheus'
            - '--storage.tsdb.retention.time=168h'
            - '--web.enable-lifecycle'
            - '--storage.tsdb.no-lockfile'
            - '--web.route-prefix=/'
            - '--web.listen-address=0.0.0.0:9090'
          image: 'harbor.axzo.cn/library/prometheus:2.53.1'
          imagePullPolicy: IfNotPresent
          name: prometheus
          ports:
            - containerPort: 9090
              protocol: TCP
          volumeMounts:
            - mountPath: /etc/prometheus
              name: prometheus-config
            - mountPath: /prometheus
              name: prometueus-data
      serviceAccount: prometheus
      serviceAccountName: prometheus
      terminationGracePeriodSeconds: 30
      volumes:
        - configMap:
            defaultMode: 420
            name: prometheus-config
          name: prometheus-config
        - name: prometueus-data
          persistentVolumeClaim:
            claimName: prometueus-data
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: prometheus
  name: prometheus
  namespace: thanos
spec:
  ports:
    - name: prometheus
      port: 9090
      protocol: TCP
      targetPort: 9090
    - name: thanos-19091
      port: 19091
      protocol: TCP
      targetPort: 19091
    - name: thanos-19191
      port: 19191
      protocol: TCP
      targetPort: 19191
  selector:
    app: prometheus
```

# 安装Node-Exporter
```yaml
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: node-exporter
  namespace: thanos
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
        - name: host
          hostPath:
            path: /
      containers:
        - name: node-exporter
          ports:
            - containerPort: 9100
          image: harbor.axzo.cn/library/node-exporter:latest
          args:
            - '--path.procfs=/host/proc'
            - '--path.sysfs=/host/sys'
            - '--path.rootfs=/host'
            - '--collector.arp'
            - '--collector.bcache'
            - '--collector.bonding'
            - '--no-collector.buddyinfo'
            - '--collector.conntrack'
            - '--collector.cpu'
            - '--collector.diskstats'
            - '--no-collector.drbd'
            - '--collector.edac'
            - '--collector.entropy'
            - '--collector.filefd'
            - '--collector.filesystem'
            - '--collector.hwmon'
            - '--collector.infiniband'
            - '--no-collector.interrupts'
            - '--collector.ipvs'
            - '--no-collector.ksmd'
            - '--collector.loadavg'
            - '--no-collector.logind'
            - '--collector.mdadm'
            - '--collector.meminfo'
            - '--no-collector.meminfo_numa'
            - '--no-collector.mountstats'
            - '--collector.netdev'
            - '--collector.netstat'
            - '--collector.nfs'
            - '--collector.nfsd'
            - '--no-collector.ntp'
            - '--no-collector.processes'
            - '--no-collector.qdisc'
            - '--no-collector.runit'
            - '--collector.sockstat'
            - '--collector.stat'
            - '--no-collector.supervisord'
            - '--no-collector.systemd'
            - '--no-collector.tcpstat'
            - '--collector.textfile'
            - '--collector.time'
            - '--collector.timex'
            - '--collector.uname'
            - '--collector.vmstat'
            - '--no-collector.wifi'
            - '--collector.xfs'
            - '--collector.zfs'
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 30Mi
          volumeMounts:
            - name: proc
              readOnly: true
              mountPath: /host/proc
            - name: sys
              readOnly: true
              mountPath: /host/sys
            - name: host
              readOnly: true
              mountPath: /host
      nodeSelector:
        kubernetes.io/os: linux
      hostNetwork: true
      hostPID: true
      securityContext:
        runAsUser: 65534
        runAsNonRoot: true
      tolerations:
        - operator: Exists
```

# 安装Thanos

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thanos-query
  namespace: thanos
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: thanos-query
  template:
    metadata:
      labels:
        app.kubernetes.io/name: thanos-query
    spec:
      containers:
        - args:
            - query
            - '--grpc-address=0.0.0.0:19091'
            - '--http-address=0.0.0.0:9090'
            - '--log.level=info'
            - '--log.format=logfmt'
            - '--endpoint=prometheus:19091'
            - '--query.auto-downsampling'
          image: 'harbor.axzo.cn/library/thanos:latest'
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 4
            httpGet:
              path: /-/healthy
              port: 9090
              scheme: HTTP
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 1
          name: thanos-query
          readinessProbe:
            failureThreshold: 20
            httpGet:
              path: /-/ready
              port: 9090
              scheme: HTTP
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 1
          resources:
            limits:
              cpu: '4'
              memory: 4Gi
            requests:
              cpu: '2'
              memory: 4Gi
      imagePullSecrets:
        - name: harbor
      nodeSelector:
        kubernetes.io/os: linux
      securityContext:
        fsGroup: 65534
        runAsUser: 65534
      terminationGracePeriodSeconds: 120
```