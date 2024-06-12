---
title: Filebeat安装
date: 2024-06-11 14:12:17
tags: ELK
categories: ELK
---

# 安装

[官方文档](https://www.elastic.co/guide/en/beats/filebeat/7.14/filebeat-installation-configuration.html)

```bash
mkdir ~/downloads
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.14.2-x86_64.rpm -O ~/downloads/filebeat-7.14.2-x86_64.rpm
yum install -y ~/downloads/filebeat-7.14.2-x86_64.rpm
```

# 配置
```bash
cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.default
```