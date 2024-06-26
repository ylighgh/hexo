---
title: Kubernetes-日志采集
date: 2024-05-29 22:26:00
tags: Kubernetes
categories: Kubernetes
---
# 容器日志采集

基于 FluentBit + Kafka + ELK 的日志采集系统

# 创建namespace

```bash
kubectl create ns logging
```

# 消息队列

## Zookeeper
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
  namespace: logging
spec:
  selector:
    matchLabels:
      app: zookeeper
  serviceName: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      containers:
        - name: zookeeper
          image: harbor.axzo.cn/ops/zookeeper:3.9.2
          ports:
            - containerPort: 2181
              name: zookeeperclient
      imagePullSecrets:
        - name: harbor
---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper   # 与serviceName 同名
  namespace: logging
spec:
  clusterIP: None
  ports:
    - port: 2181
  selector:
    app: zookeeper
EOF
```

## Kafka
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: logging
spec:
  selector:
    matchLabels:
      app: kafka
  serviceName: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      imagePullSecrets:
        - name: harbor
      containers:
        - name: kafka
          image: harbor.axzo.cn/ops/kafka:3.3.2
          ports:
            - containerPort: 9092
              name: service
          env:
            - name: ALLOW_ANONYMOUS_LOGIN
              value: "yes"
            - name: KAFKA_CFG_ZOOKEEPER_CONNECT
              value: "zookeeper:2181"
            - name: ALLOW_PLAINTEXT_LISTENER
              value: "yes"
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: logging
spec:
  clusterIP: None
  ports:
    - port: 9092
  selector:
    app: kafka
EOF
```

## 配置

```bash
# 创建topic
kubectl exec -it kafka-0 -n logging -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --bootstrap-server kafka:9092 --replication-factor 1 --partitions 1 --topic k8s-logs

# 列出topic
kubectl exec -it kafka-0 -n logging -- /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka:9092
```

# FluentBit

## 配置
```
kubectl apply -f - <<EOF
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluent-bit-config
  namespace: logging
  labels:
    k8s-app: fluent-bit
data:
  filter.conf: |-
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     kube.var.log.containers.
        Merge_Log           On
        K8S-Logging.Parser  On
        K8S-Logging.Exclude Off
        Annotations         Off
    [FILTER]
        Name           grep
        Match          kube.*
        regex         \$kubernetes['labels']['logging'] true
    [FILTER]
        Name record_modifier
        Match kube.*
        Remove_key kubernetes.container*
        Remove_key kubernetes.pod_id
        Remove_key kubernetes.docker_id
        Remove_key kubernetes.labels
        Remove_key log
  fluent-bit.conf: |-
    [SERVICE]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020

    @INCLUDE input.conf
    @INCLUDE filter.conf
    @INCLUDE output-kafka.conf
  input.conf: |-
    [INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/containers/*.log
        Parser            docker
        DB                /var/log/flb_kube.db
        Mem_Buf_Limit     1MB
        Skip_Long_Lines   On
        Refresh_Interval  10
  output-kafka.conf: |-
    [OUTPUT]
        Name           kafka
        Match          kube.*
        Brokers        kafka:9092
        Topics         k8s-logs
        Timestamp_Key  @timestamp
        Timestamp_Format iso8601
        Retry_Limit    false
        # hides errors "Receive failed: Disconnected" when kafka kills idle connections
        rdkafka.log.connection.close false
        # producer buffer is not included in http://fluentbit.io/documentation/0.12/configuration/memory_usage.html#estimating
        rdkafka.queue.buffering.max.kbytes 20240
        # for logs you'll probably want this ot be 0 or 1, not more
        rdkafka.request.required.acks 1
  parsers.conf: |-
    [PARSER]
        Name axzo_json
        Format json
    [PARSER]
        Name   apache
        Format regex
        Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?\$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   apache2
        Format regex
        Regex  ^(?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^ ]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?\$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   apache_error
        Format regex
        Regex  ^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\](?: \[pid (?<pid>[^\]]*)\])?( \[client (?<client>[^\]]*)\])? (?<message>.*)\$

    [PARSER]
        Name   nginx
        Format regex
        Regex ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?\$
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name   json
        Format json
        Time_Key time
        Time_Format %d/%b/%Y:%H:%M:%S %z

    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep   On

    [PARSER]
        Name        syslog
        Format      regex
        Regex       ^\<(?<pri>[0-9]+)\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)\$
        Time_Key    time
        Time_Format %b %d %H:%M:%S

    [PARSER]
        Name        axzo-os-log
        Format      regex
        Regex       ^(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<process>[^ ]*)\: (?<message>.*)\$
        Time_Key    time
        Time_Format %b %d %H:%M:%S
EOF
```
## Serviceaccount
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: logging
EOF
```
## clusterroles
```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit-read
rules:
- apiGroups:
  - ""
  resources:
  - namespaces
  - pods
  verbs:
  - get
  - list
  - watch
EOF
```

## clusterrolebindings
```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit-read
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: logging
EOF
```

## 服务
```bash
kubectl apply -f - <<EOF
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: fluent-bit
  namespace: logging
  labels:
    k8s-app: fluent-bit-logging
    kubernetes.io/cluster-service: 'true'
    version: v1
spec:
  selector:
    matchLabels:
      k8s-app: fluent-bit-logging
  template:
    metadata:
      labels:
        k8s-app: fluent-bit-logging
        kubernetes.io/cluster-service: 'true'
        version: v1
    spec:
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
            type: ''
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
            type: ''
        - name: fluent-bit-config
          configMap:
            name: fluent-bit-config
            defaultMode: 420
      containers:
        - name: fluent-bit
          image: 'harbor.axzo.cn/ops/fluent-bit:1.8.0'
          ports:
            - name: 2020tcp02
              containerPort: 2020
              protocol: TCP
          resources:
            limits:
              cpu: 500m
              memory: 256Mi
            requests:
              cpu: 100m
              memory: 256Mi
          volumeMounts:
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              readOnly: true
              mountPath: /var/lib/docker/containers
            - name: fluent-bit-config
              mountPath: /fluent-bit/etc/
          livenessProbe:
            httpGet:
              path: /
              port: 2020
              scheme: HTTP
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /api/v1/metrics/prometheus
              port: 2020
              scheme: HTTP
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: Always
          securityContext:
            capabilities: {}
      restartPolicy: Always
      terminationGracePeriodSeconds: 11
      dnsPolicy: ClusterFirst
      serviceAccountName: fluent-bit
      serviceAccount: fluent-bit
      securityContext: {}
      imagePullSecrets:
        - name: harbor
      schedulerName: default-scheduler
      tolerations:
        - key: node-role.kubernetes.io/master
          operator: Exists
          effect: NoSchedule
        - operator: Exists
          effect: NoExecute
        - operator: Exists
          effect: NoSchedule
      dnsConfig:
        options:
          - name: single-request-reopen
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 3
  revisionHistoryLimit: 10
EOF
```

# ELK

## ElasticSearch
```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
spec:
  ports:
  - port: 9200
    protocol: TCP
    targetPort: db
  selector:
    app: elasticsearch
---
# RBAC authn and authz
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elasticsearch
  namespace: logging
  labels:
    app: elasticsearch
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: elasticsearch
  labels:
    app: elasticsearch
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - "services"
  - "namespaces"
  - "endpoints"
  verbs:
  - "get"
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: logging
  name: elasticsearch
  labels:
    app: elasticsearch
subjects:
- kind: ServiceAccount
  name: elasticsearch
  namespace: logging
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: elasticsearch
  apiGroup: ""
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: es-data
  namespace: logging
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: everest-csi-provisioner
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-client
  volumeMode: Filesystem
---
# Elasticsearch deployment itself
apiVersion: apps/v1
kind: StatefulSet #使用statefulset创建Pod
metadata:
  name: elasticsearch #pod名称,使用statefulSet创建的Pod是有序号有顺序的
  namespace: logging  #命名空间
  labels:
    app: elasticsearch
spec:
  replicas: 1 #副本数量,单节点
  selector:
    matchLabels:
      app: elasticsearch #和pod template配置的labels相匹配
  template:
    metadata:
      labels:
        app: elasticsearch
        kubernetes.io/cluster-service: "true"
    spec:
      serviceAccountName: elasticsearch
      imagePullSecrets:
        - name: harbor
      volumes:
      - name: es-data
        persistentVolumeClaim:
          claimName: es-data
      - name: localtime
        hostPath:
          path: /etc/localtime
      containers:
      - image: harbor.axzo.cn/ops/elasticsearch:8.14.1
        name: elasticsearch
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
            memory: 2Gi
          requests:
            cpu: 100m
            memory: 500Mi
        ports:
        - containerPort: 9200
          name: db
          protocol: TCP
        - containerPort: 9300
          name: transport
          protocol: TCP
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data/   #挂载点
        - name: localtime
          readOnly: true
          mountPath: /etc/localtime
        env:
        - name: "NAMESPACE"
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: "discovery.type"  #定义单节点类型
          value: "single-node"
        - name: ES_JAVA_OPTS #设置Java的内存参数，可以适当进行加大调整
          value: "-Xms512m -Xmx2g" 
EOF
```

## LogStash
```bash

harbor.axzo.cn/ops/logstash:8.14.1
```

## Kibana
```bash
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
  labels:
    k8s-app: kibana
spec:
  type: NodePort #采用nodeport方式进行暴露，端口默认为25601
  ports:
  - port: 5601
    nodePort: 32601
    protocol: TCP
    targetPort: ui
  selector:
    k8s-app: kibana
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
  labels:
    k8s-app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: kibana
  template:
    metadata:
      labels:
        k8s-app: kibana
    spec:
      imagePullSecrets:
        - name: harbor
      volumes:
      - name: localtime
        hostPath:
          path: /etc/localtime
      containers:
      - name: kibana
        image: harbor.axzo.cn/ops/kibana:8.14.1
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 1000m
          requests:
            cpu: 100m
        env:
          - name: ELASTICSEARCH_HOSTS
            value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
          name: ui
          protocol: TCP
        volumeMounts:
        - name: localtime
          readOnly: true
          mountPath: /etc/localtime
EOF
```