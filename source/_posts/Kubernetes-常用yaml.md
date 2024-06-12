---
title: Kubernetes-常用YAML
date: 2024-05-29 22:26:00
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
        topics => "k8s-apisix-logs"
        consumer_threads => 50
        decorate_events => true
        codec => json
        auto_offset_reset => "latest"
     }
    }
    filter {
            mutate {
                convert => ["request_length","integer"]
                convert => ["duration","float"]
                convert => ["body_bytes_sent","integer"]
                convert => ["upstream_status","integer"]
                convert => ["upstream_response_time","float"]
                convert => ["request_time","float"]
                convert => ["bytes_sent","integer"]
                convert => ["status","integer"]
            }
            geoip {
                source => "remote_addr"
            }
    }
    output {
      elasticsearch {
        hosts => ["192.168.1.65:9200","192.168.1.150:9200","192.168.1.32:9200","192.168.1.44:9200","192.168.1.89:9200"]
        user => "elastic"
        password => "xxx"
        index => "logstash-apisix-%{+YYYY.MM.dd}"
      }
      # DEBUG
       #stdout { 
        #codec  => rubydebug {
        #metadata => true
      #}
  }
    }
  logstash.yml: |
    http.host: "0.0.0.0"
    path.config: /usr/share/logstash/pipeline
EOF
```