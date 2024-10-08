---
title: Kubernetes-常用YAML
date: 2024-08-04 14:44:34
tags: Kubernetes
categories: Kubernetes
---

# logstash

## 服务
```bash
kubectl apply -f - <<EOF
kind: Deployment
apiVersion: apps/v1
metadata:
  name: logstash-os
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash-os
  template:
    metadata:
      labels:
        app: logstash-os
    spec:
      volumes:
        - name: config-volume
          configMap:
            name: logstash-os-configmap
            items:
              - key: logstash.yml
                path: logstash.yml
            defaultMode: 420
        - name: logstash-pipeline
          configMap:
            name: logstash-os-configmap
            items:
              - key: logstash.conf
                path: logstash.conf
            defaultMode: 420
        - name: localtime
          hostPath:
            path: /etc/localtime
            type: ''
      containers:
        - name: logstash
          image: 'harbor.axzo.cn/ops/logstash:7.14.0'
          resources:
            limits:
              cpu: '1'
              memory: 1Gi
            requests:
              cpu: 500m
              memory: 1Gi
          volumeMounts:
            - name: config-volume
              mountPath: /usr/share/logstash/config
            - name: logstash-pipeline
              mountPath: /usr/share/logstash/pipeline
            - name: localtime
              mountPath: /etc/localtime
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      imagePullSecrets:
        - name: harbor
      schedulerName: default-scheduler
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
EOF
```

## 配置
```bash
kubectl apply -f - <<EOF
kind: ConfigMap
apiVersion: v1
metadata:
  name: logstash-os-configmap
  namespace: logging
data:
  logstash.conf: |
    input{
      kafka{
        bootstrap_servers => "192.168.1.9:9091,192.168.1.9:9092,192.168.1.9:9093"
        topics => ["os-secure-logs", "os-messages-logs"]
        consumer_threads => 1
        decorate_events => true
        codec => json
        auto_offset_reset => "latest"
     }
    }
    filter{
      ruby { 
              code => "event.set('timestamp', event.get('@timestamp').time.localtime - 8*60*60)" 
          }
        mutate {
            remove_field => ["@version", "@timestamp"]
        }
    }
    output {
      stdout { 
         codec  => rubydebug {
           metadata => true
         }
      }
      if "os-secure-logs" == [@metadata][kafka][topic] {
        elasticsearch {
          hosts => ["192.168.1.65:9200","192.168.1.150:9200","192.168.1.32:9200","192.168.1.44:9200","192.168.1.89:9200"]
          user => "elastic"
          password => "axzo@2021"
          index => "logstash-os-secure-%{+YYYY.MM.dd}"
        }
      } else {
        elasticsearch {
          hosts => ["192.168.1.65:9200","192.168.1.150:9200","192.168.1.32:9200","192.168.1.44:9200","192.168.1.89:9200"]
          user => "elastic"
          password => "axzo@2021"
          index => "logstash-os-messages-%{+YYYY.MM.dd}"
        }
      }
    }
  logstash.yml: |
    http.host: "0.0.0.0"
    path.config: /usr/share/logstash/pipeline
EOF
```


# PVC
```bash
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pro-apisix-plugins
  namespace: pro-apisix
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: everest-csi-provisioner
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: sfsturbo-k8s-sc
  volumeMode: Filesystem
EOF
```

# NFS-server
```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kubernetes.io/metadata.name: storage
  name: storage
---
apiVersion: v1
data:
  exports: '/data/nfs *(rw,fsid=0,insecure,no_root_squash)'
kind: ConfigMap
metadata:
  name: nfs-server-conf
  namespace: storage
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-server
  namespace: storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  template:
    metadata:
      labels:
        app: nfs-server
    spec:
      volumes:
        - name: nfs-server-conf
          configMap:
            name: nfs-server-conf
            defaultMode: 420
        - name: nfs-data
          persistentVolumeClaim:
            claimName: nfs-data
      containers:
        - name: nfs-server
          image: harbor.axzo.cn/library/nfs-server:v1
          ports:
            - name: nfs
              containerPort: 2049
              protocol: TCP
            - name: mountd
              containerPort: 20048
              protocol: TCP
            - name: rpcbind
              containerPort: 111
              protocol: TCP
          volumeMounts:
            - name: nfs-server-conf
              readOnly: true
              mountPath: /etc/exports
              subPath: exports
            - mountPath: /data/nfs
              name: nfs-data
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
---
apiVersion: v1
kind: Service
metadata:
  name: nfs-service
  namespace: storage
spec:
  ports:
    - name: nfs
      port: 2049
      protocol: TCP
      targetPort: 2049
    - name: mountd
      port: 20048
      protocol: TCP
      targetPort: 20048
    - name: rpcbind
      port: 111
      protocol: TCP
      targetPort: 111
  selector:
    app: nfs-server
```