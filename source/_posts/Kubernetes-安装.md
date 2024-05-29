---
title: Kubernetes-安装
date: 2024-05-28 22:44:21
tags: Kubernetes
category_bar: ["Kubernetes"]
---

## 初始化
```bash
hostnamectl set-hostname k8s-node

modprobe overlay
modprobe br_netfilter

cat <<EOF> /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF> /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

cat <<EOF>> /etc/hosts
192.168.10.242 k8s-master
192.168.10.245 k8s-node1
192.168.10.246 k8s-node2
192.168.10.247 k8s-node3
EOF

sysctl --system

systemctl stop firewalld
systemctl disable firewalld
systemctl unmask firewalld
```

## 安装Containerd

```bash
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf update
dnf install -y containerd
```

## 配置Containerd
```bash
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
```

## 重启containerd
```bash
systemctl daemon-reload
systemctl restart containerd
systemctl enable --now containerd
systemctl status containerd
```

## 安装kubeadm
```bash
cat <<EOF>/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet
```

## master节点执行
```bash
kubeadm init \
--apiserver-advertise-address=192.168.10.242 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.96.0.0/12 \
--pod-network-cidr=10.244.0.0/16
```
执行成功
```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf
```

## 将其他node加入集群
在其他节点执行
```bash
kubeadm join 192.168.10.242:6443 --token ijblbd.bmnaf8xcl38iwxbz \
	--discovery-token-ca-cert-hash sha256:1d76ad35d2d95c6b381ada3d03b15f230201e9e0af41db4db33700d7de604e1d 
```


## 部署CNI网络组件
```bash
wget https://docs.projectcalico.org/manifests/calico.yaml

- 修改IPV4POOL地址

kubectl create -f calico.yaml
```