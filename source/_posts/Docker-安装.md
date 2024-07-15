---
title: Docker-安装
date: 2024-07-15 22:44:21
tags: Docker
categories: Docker
---

# 安装
```bash
dnf install -y device-mapper-persistent-data lvm2

dnf config-manager --add-repo=https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

dnf install -y docker-ce --nobest

docker -v

systemctl start docker

systemctl enable docker

systemctl status docker
```