---
title: FluentBit安装
date: 2024-06-11 14:12:17
tags: ELK
categories: ELK
---

# 安装

[官方文档](https://docs.fluentbit.io/manual/installation/getting-started-with-fluent-bit)

```bash
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
```

# 备份默认文件
```bash
cp /etc/fluent-bit/fluent-bit.conf /etc/fluent-bit/fluent-bit.conf.default
cp /etc/fluent-bit/parsers.conf /etc/fluent-bit/fparsers.conf.default
```

# 修改配置
## 配置IP
```bash
export IP=x.x.x.x
```

## 修改主配置文件
```bash
cat <<EOF>/etc/fluent-bit/fluent-bit.conf
[SERVICE]
    flush        1
    daemon       Off
    log_level    info
    parsers_file parsers.conf
    plugins_file plugins.conf

@INCLUDE secure-input.conf
@INCLUDE secure-filter.conf
@INCLUDE secure-output.conf
@INCLUDE messages-input.conf
@INCLUDE messages-filter.conf
@INCLUDE messages-output.conf
EOF
```

## 增加parser配置
```bash
cat <<EOF>> /etc/fluent-bit/parsers.conf

[PARSER]
    Name axzo-os-log
    Format regex
    Regex ^(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<hostname>[^ ]*) (?<process>[^ ]*)\: (?<message>.*)$
    Time_Key    time
    Time_Format %b %d %H:%M:%S
EOF
```

## 采集secure日志配置
```bash
cat <<EOF> /etc/fluent-bit/secure-input.conf
[INPUT]
    Name tail
    Path /var/log/secure
    Tag kube-secure.*
    DB                /var/log/flb_kube_secure.db
    Mem_Buf_Limit     1MB
    Skip_Long_Lines   On
    Refresh_Interval  10
EOF

cat <<EOF> /etc/fluent-bit/secure-filter.conf
[FILTER]
    Name grep
    Match kube-secure.*
    Regex log /.*sshd.*/

[FILTER]
    Name parser
    Match kube-secure.*
    Key_Name log
    Parser axzo-os-log

[FILTER]
    Name modify
    Match kube-secure.*
    Add IP $IP
EOF

cat <<EOF> /etc/fluent-bit/secure-output.conf
[OUTPUT]
    Name           kafka
    Match          kube-secure.*
    Brokers        192.168.1.9:9092,192.168.1.9:9091,192.168.1.9:9093
    Topics         os-secure-logs
    Timestamp_Key  @timestamp
    Timestamp_Format iso8601
    Retry_Limit    false
    # hides errors "Receive failed: Disconnected" when kafka kills idle connections
    rdkafka.log.connection.close false
    # producer buffer is not included in http://fluentbit.io/documentation/0.12/configuration/memory_usage.html#estimating
    rdkafka.queue.buffering.max.kbytes 20240
    # for logs you'll probably want this ot be 0 or 1, not more
    rdkafka.request.required.acks 1
EOF
```

## 采集message kernel日志
```bash
cat <<EOF>/etc/fluent-bit/messages-input.conf
[INPUT]
    Name tail
    Path /var/log/messages
    Tag kube-messages.*
    DB                /var/log/flb_kube_messages.db
    Mem_Buf_Limit     1MB
    Skip_Long_Lines   On
    Refresh_Interval  10
EOF

cat <<EOF> /etc/fluent-bit/messages-filter.conf
[FILTER]
    Name grep
    Match kube-messages.*
    Regex log /.*kernel.*/

[FILTER]
    Name parser
    Match kube-messages.*
    Key_Name log
    Parser axzo-os-log

[FILTER]
    Name modify
    Match kube-messages.*
    Add IP $IP
EOF

cat <<EOF>/etc/fluent-bit/messages-output.conf
[OUTPUT]
    Name           kafka
    Match          kube-messages.*
    Brokers        192.168.1.9:9092,192.168.1.9:9091,192.168.1.9:9093
    Topics         os-messages-logs
    Timestamp_Key  @timestamp
    Timestamp_Format iso8601
    Retry_Limit    false
    # hides errors "Receive failed: Disconnected" when kafka kills idle connections
    rdkafka.log.connection.close false
    # producer buffer is not included in http://fluentbit.io/documentation/0.12/configuration/memory_usage.html#estimating
    rdkafka.queue.buffering.max.kbytes 20240
    # for logs you'll probably want this ot be 0 or 1, not more
    rdkafka.request.required.acks 1
EOF
```

# 启动
```bash
systemctl start fluent-bit
systemctl enable fluent-bit
systemctl status fluent-bit
```