---
title: Linux-常用Shell命令
date: 2024-06-11 14:12:17
tags: Linux
categories: Linux
---

# 批量删除指定状态的pods
```bash
kubectl --kubeconfig gxq-config get pods -A|grep Evicted|awk '{print $1" "$2}'|while read LINE
do
    namespace=`echo $LINE|awk '{print $1}'`
    pod=`echo $LINE|awk '{print $2}'`
    kubectl --kubeconfig gxq-config delete pod -n $namespace $pod
done
```

# 阿里云增加DNS解析
```bash
# A记录
aliyun alidns AddDomainRecord --region cn-beijing --DomainName 'xx.cn' --Type A --RR 'www' --Value '1.1.1.1'

# CNAME
aliyun alidns AddDomainRecord --region cn-beijing --DomainName 'xx.cn' --Type CNAME --RR 'xxx' --Value 'bbb.yy.cn'
```



# 安装Node Expoter
```bash
# 一句话安装
curl http://47.109.36.211:9090/install_node_expoter.sh | bash
```

```bash
#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Define variables
DOWNLOAD_URL="http://47.109.36.211:9090/node_exporter-1.8.2.linux-amd64.tar.gz"
DOWNLOAD_DIR="/tmp/downloads"
INSTALL_DIR="/opt/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
LOCK_FILE="/root/.node_exporter_install.lock"

# Check if the lock file exists
if [ -f $LOCK_FILE ]; then
  echo "Node Exporter is already installed. Exiting."
  exit 0
fi

# Create necessary directories
mkdir -p $DOWNLOAD_DIR $INSTALL_DIR

# Download and extract node_exporter
wget $DOWNLOAD_URL -O $DOWNLOAD_DIR/node_exporter.tar.gz
tar xf $DOWNLOAD_DIR/node_exporter.tar.gz -C $DOWNLOAD_DIR
mv $DOWNLOAD_DIR/node_exporter-*/node_exporter $INSTALL_DIR/
rm -rf $DOWNLOAD_DIR/node_exporter*

# Create systemd service file
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target

[Service]
User=root
ExecStart=$INSTALL_DIR/node_exporter
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration and start the service
systemctl daemon-reload
systemctl enable --now node_exporter

# Create lock file
touch $LOCK_FILE

echo "Node Exporter installation and configuration completed"
```

