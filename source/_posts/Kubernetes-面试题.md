---
title: Kubernetes-基础
date: 2024-09-10 11:48:13
tags: Kubernetes
categories: Kubernetes
---

# 常见面试问题


1. K8S是什么

> K8S是一个容器编排的平台,简单来说,就是管理分布在不同主机上的容器,让他们更好的协同工作.

2. K8S的优点和缺点

优点
> - 自愈: 通过探针进行容器健康检查,不满足健康检查条件,自动重启容器.
> - 服务发现和负载均衡: 使用DNS名称进行负载负载均衡分配网络流量,从而使部署稳定.
> - 存储编排: 更好的管理本地存储或者公共云提供的存储
> - 自动部署和回滚: 按照yaml文件中的期望状态进行自动化创建容器,或者通过历史记录进行快速回滚
> - 自动完成装箱计算: 允许指定每个容器所需的硬件资源(CPU,MEM,GPU),当容器请求资源时,按照预定的资源进行分配
> - 强大的扩展性: 支持水平和垂直扩展,根据应用需求动态调整资源(日常资源池和弹性资源池)
> - 高可用和容错性: 部分节点出现故障,容器会被自动调度到正常节点的容器上

缺点
> - 成本刺客: 资源消耗大, k8s需要多组件和多节点运行,资源随着业务的增长会不断的增加,导致成本增加
> - 简单复杂化: 对于小型网站或公司,如果硬上K8S是完全没有必要的

3. Pod Pending状态的原因

[资料参考](https://cloud.tencent.com/document/product/457/42948)

> - 节点资源不足(PVC未创建等...)
> - 不满足 nodeSelector 与 affinity
> - Node 存在 Pod 没有容忍的污点
> - 低版本 kube-scheduler 的 bug
> - kube-scheduler 未正常运行
> - 驱逐后其他可用节点与当前节点的有状态应用不在相同可用区

4. K8S Pod的启动过程

client向APIServer发送创建pod的请求：[资料参考](https://segmentfault.com/a/1190000040817721)

> 1. APIServer将pod信息存入etcd，通知Scheduler
> 2. Scheduler根据调度算法，为pod选择一个节点，然后向APIServer发送更新spec.nodeName
> 3. APIServer更新完毕，通知对应节点的kubelet
> 4. kubelet发现pod调度到本节点，创建并运行pod的容器

5. K8S 网络模型 

|  对比项   | Terway  | Flannel  | Calico  |
|  ----  | ----  | ----  | ----  |
| 性能  | Pod地址即为VPC中地址,无NAT损耗支持独占ENI模式,几乎无损 |配合阿里云VPC路由,Pod地址为虚拟地址,存在NAT转换损耗 |Calico 使用纯三层路由，不依赖 NAT，支持 BGP 协议，性能较高，但在高流量环境下相对 Terway 可能有一定开销，尤其是在复杂路由场景中 |
| 安全  | 支持使用网络策略Network Policy |不支持使用网络策略Network Policy |支持使用网络策略Network Policy，并提供高级的网络策略功能，如基于标签的访问控制和细粒度策略管理
 |
| 地址管理  | 无需按节点分配地址段,随用随分配,无地址浪费 |节点维度划分地址段,大规模集群下地址浪费多 |使用基于 BGP 路由的三层网络模式，IP 分配相对灵活，但配置复杂度高，在某些场景下可能需要进行子网规划
 |
| 负载均衡  | SLB后端直接对接Pod,支持业务无中断升级 |SLB后端不能直接对接Pod,需要通过NodePort转发 |支持通过 Service 或 Ingress 实现负载均衡，Pod 直接作为负载均衡后端，但由于网络封装（如 VXLAN/IPIP）可能带来一定开销 |


6. K8S 其他面试题

[资料参考](https://github.com/0voice/k8s_awesome_document/blob/main/91%E9%81%93%E5%B8%B8%E8%A7%81%E7%9A%84Kubernetes%E9%9D%A2%E8%AF%95%E9%A2%98%E6%80%BB%E7%BB%93.md)