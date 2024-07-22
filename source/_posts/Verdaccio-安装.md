---
title: Verdaccio-安装
date: 2024-07-22 22:44:21
tags: Verdaccio
categories: Verdaccio
---

# Verdaccio安装

前端私服库: [官方文档](https://verdaccio.org/docs/installation)

## 安装node环境
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 18

ln -s "$(which node)" /usr/bin/node
ln -s "$(which npm)" /usr/bin/npm

npm install -g npm@10.5.0
```

## 安装verdaccio
```bash
npm install --location=global verdaccio

ln -s "$(which verdaccio)" /usr/bin/verdaccio
```

## 配置verdaccio
```bash
mkdir /verdaccio
cd /verdaccio

# 启动了之后马上暂停,这一步主要是让verdaccio自动创建配置文件
verdaccio

# 增加systemd文件
cat <<EOF> /etc/systemd/system/verdaccio.service
[Unit]
Description=Verdaccio lightweight npm proxy registry

[Service]
Type=simple
Restart=on-failure
ExecStart=/usr/bin/verdaccio --config /verdaccio/config.yaml
SyslogIdentifier=verdaccio
StandardOutput=append:/var/log/verdaccio/verdaccio.log
StandardError=syslog


[Install]
WantedBy=multi-user.target
EOF

# 创建日志轮替
cat <<EOF> /etc/logrotate.d/verdaccio
/var/log/verdaccio/*.log {
        daily
        missingok
        rotate 7
        compress
        delaycompress
        notifempty
	dateext
        create 640 root root
        sharedscripts
        postrotate
	   /usr/bin/systemctl restart verdaccio
	   /usr/bin/systemctl restart rsyslog
        endscript
}
EOF

systemctl daemon-reload
```

## 启动verdaccio
```bash
systemdct enable verdaccio
systemctl start verdaccio
```