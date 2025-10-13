---
title: Kubernetes-v1.34-安装
date: 2025-10-13 22:44:21
tags: Kubernetes
categories: Kubernetes
---

# 🚀 第一步：准备系统环境
```bash
# 更新系统
dnf update -y

# 设置主机名
hostnamectl set-hostname <node-name>

# 将主机名加入 /etc/hosts
echo "127.0.0.1 $(hostname)" >> /etc/hosts

# 关闭 SELinux（临时 + 永久）
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# 禁用 Swap（临时 + 永久）
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 启用网桥转发模块
modprobe br_netfilter

# 配置内核模块自动加载
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

# 配置系统网络参数
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# 使配置立即生效
sysctl --system
```

# 🐳 第二步：安装 Containerd 容器运行时
```bash
# 安装依赖
dnf -y install dnf-plugins-core

# 添加 Docker 官方仓库
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 containerd
dnf install -y containerd

# 创建配置目录
mkdir -p /etc/containerd

# 生成默认配置文件
containerd config default | tee /etc/containerd/config.toml

# 修改 cgroup 驱动为 systemd
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# 启动并设置开机自启
systemctl enable --now containerd
```

# 🧩 第三步：安装 Kubernetes 组件

## 添加 Kubernetes 官方仓库
```bash
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
EOF
```

## 安装 kubelet、kubeadm、kubectl
```bash
dnf install -y kubelet kubeadm kubectl

# 启用 kubelet 服务
systemctl enable kubelet
```

# 🧠 第四步：初始化控制节点（Master）
```bash
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=<MASTER_IP>

# 配置 kubectl 管理权限
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

# 🌐 第五步：部署 Flannel 网络插件
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

# 🧑‍🤝‍🧑 第六步：将工作节点加入集群
在控制节点上运行以下命令以生成加入命令：
```bash
kubeadm token create --print-join-command
```

输出示例：
```bash
kubeadm join MASTER_IP:6443 --token 0iax3l.5xa5l61mspqet \
  --discovery-token-ca-cert-hash sha256:5660b8sfak43e56sf3dpi13jdd1d4ecde06d55bfed842g3mf1d793daeb9549f4ba3
```

👉 将以上命令复制到 每个工作节点 上执行，即可加入集群。

🔍 第七步：验证集群状态
```bash
# 创建一个测试应用
kubectl create deployment nginx --image=nginx

# 暴露服务（NodePort 方式）
kubectl expose deployment nginx --port=80 --type=NodePort

# 查看服务信息
kubectl get svc
```

输出示例：
```bash
NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.96.232.101   <none>        80:31547/TCP   10s
```

然后使用浏览器访问：
```
http://<NodeIP>:31547
```