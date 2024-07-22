---
title: Jenkins-安装
date: 2024-07-22 22:44:21
tags: Jenkins
categories: Jenkins
---

# 安装

## 创建Role RoleBinding
```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-blue
  namespace: kube-ops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-blue
subjects:
- kind: ServiceAccount
  name: jenkins-blue
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-blue
  namespace: kube-ops
rules:
- apiGroups:
  - extensions
  - apps
  resources:
  - deployments
  verbs:
  - create
  - delete
  - get
  - list
  - watch
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - create
  - delete
  - get
  - list
  - watch
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - pods/exec
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - pods/log
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
EOF
```

## 创建serviceAccount,并创建sa的sercret
```bash
kubectl apply -f - <<EOF
apiVersion: v1
automountServiceAccountToken: true
kind: ServiceAccount
metadata:
  name: jenkins-blue
  namespace: kube-ops
secrets:
- name: jenkins-blue
---
apiVersion: v1
kind: Secret
metadata:
  name: jenkins-blue
  namespace: kube-ops
  annotations:
    kubernetes.io/service-account.name: "jenkins-blue"
type: kubernetes.io/service-account-token
EOF
```


## 创建configmaps
```bash
kubectl apply -f - <<EOF
apiVersion: v1
data:
  addJavaAppStart.sh: >
    #!/bin/sh


    echo "获取包依赖关系： "

    mvn dependency:tree -D outputFile=/pipeline-stage-share/dependency_tree.txt
    -D outputType=dot -D includes=cn.axzo.*


    echo ' 

    #!/bin/bash


    # Copyright 2019-2039 AXZO Co. Ltd.

    # Licensed under the Apache License, Version 2.0 (the "License");

    # you may not use this file except in compliance with the License.

    # You may obtain a copy of the License at


    #      http://www.apache.org/licenses/LICENSE-2.0

    #

    # Unless required by applicable law or agreed to in writing, software

    # distributed under the License is distributed on an "AS IS" BASIS,

    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

    # See the License for the specific language governing permissions and

    # limitations under the License.

    artifact=\$1


    if [[ \$# -le 0 ]]; then
      echo "Usage: \$0 example.jar"
      exit 255
    fi


    readonly megabytes=1048576

    # shellcheck disable=SC2004


    # jvm堆内存占容器内存上限的比例, 如果没有设置, 则默认为60%

    if [ "\${JVM_MEM_PERCENT}" == "" ]; then
      JVM_MEM_PERCENT="60"
    fi


    # jvm堆内存数值计算, 如果容器内存上限没有设置, 则堆内存直接设置为1024m

    if [ "\${MY_MEMORY_LIMIT}" == "" ]; then
      heapmem="1024m"
    else
      heapmem=\$(printf "%sm" \$(((\$MY_MEMORY_LIMIT / \$megabytes) * \$JVM_MEM_PERCENT / 100)))
    fi


    # jvm堆内存精细化设置, 会覆盖前面的jvm堆内存设置, 并添加非堆内存的设置

    if [ x"\${JVM_MEM_HEAP}" != x ]; then
      heapmem=\${JVM_MEM_HEAP}
    fi

    if [ "\${JVM_MEM_DIRECT}" == "" ]; then
      directmem="512m"
    else
      directmem=\${JVM_MEM_DIRECT}
    fi

    if [ "\${JVM_MEM_METASPACE}" == "" ]; then
      metaspacemem="512m"
    else
      metaspacemem=\${JVM_MEM_METASPACE}
    fi


    if [ "\${JVM_OCCUPANCY_PERCENT}" == "" ]; then
      jvm_occupancy_percent="50"
    else
      jvm_occupancy_percent=\${JVM_OCCUPANCY_PERCENT}
    fi


    if [ "\${JVM_NEWSIZE_PERCENT}" == "" ]; then
      jvm_newsize_percent="60"
    else
      jvm_newsize_percent=\${JVM_NEWSIZE_PERCENT}
    fi


    export COLLECTOR="-XX:+UseG1GC -XX:ConcGCThreads=4
    -XX:+UnlockExperimentalVMOptions
    -XX:G1MaxNewSizePercent=\${jvm_newsize_percent}
    -XX:InitiatingHeapOccupancyPercent=\${jvm_occupancy_percent}
    -XX:G1HeapRegionSize=4M -XX:MaxTenuringThreshold=15 -XX:ParallelGCThreads=8"

    export LOGGER="-Xloggc:/tmp/gc.log -XX:+PrintGCDetails
    -XX:+PrintGCDateStamps"

    export HEAP="-Xmx\${heapmem} -Xms\${heapmem}"

    export NON_HEAP="-XX:MaxDirectMemorySize=\${directmem}
    -XX:MaxMetaspaceSize=\${metaspacemem}"

    export DUMP="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/dump/"

    export MON="-XX:NativeMemoryTracking=detail"


    JAVA_OPTS="\$JAVA_OPTS \${JAVA_HEAP:-\${HEAP}}"

    JAVA_OPTS="\$JAVA_OPTS \${JAVA_NON_HEAP:-\${NON_HEAP}}"

    JAVA_OPTS="\$JAVA_OPTS \${JAVA_GC:-\${COLLECTOR}}"

    JAVA_OPTS="\$JAVA_OPTS \${JAVA_LOGS:-\${LOGGER}}"

    JAVA_OPTS="\$JAVA_OPTS \${JAVA_DUMP:-\${DUMP}}"

    JAVA_OPTS="\$JAVA_OPTS \${JAVA_MON:-\${MON}}"


    # prometheus jmx agent加载, 主动开启才加载，默认不加载

    if [ "\${PROMETHEUS_JMX_AGENT}" == "true" ]; then
      JAVA_OPTS="\$JAVA_OPTS -javaagent:/mnt/jvm-agent/prometheus-javaagent/jmx_prometheus_javaagent-0.20.0.jar=12345:/mnt/jvm-agent/prometheus-javaagent/config.yaml"
    fi


    # tingyun agent加载, 主动开启才加载，默认不加载

    if [ "\${TINGYUN_JMX_AGENT}" == "true" ]; then
      JAVA_OPTS="\$JAVA_OPTS -javaagent:/mnt/skywalking-es7/agent/tingyun/tingyun-agent-java.jar -Dtingyun.app_name=\${MY_PROJECT_NAME}"
    fi


    # 其他JVM_AGENT设置, 可能会与前面的agent设置重复

    JAVA_OPTS="\$JAVA_OPTS \${JVM_AGENT}"


    # 其他JVM追加设置, 可能会与前面的设置重复

    JAVA_OPTS="\$JAVA_OPTS \${JVM_EXT_ARG}"


    # 其他固定的JAVA_OPTS

    JAVA_OPTS="\$JAVA_OPTS -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai"

    JAVA_OPTS="\$JAVA_OPTS -jar \${artifact}"


    echo "starting appliction \${artifact%????}"

    echo "running command: java \$JAVA_OPTS"

    eval "exec java \$JAVA_OPTS"


    ' > axzo_java_app_startup.sh


    JarFile=`echo \${ENTRYPOINT} | awk -F , '{print \$NF}'`

    JarFile=`echo \${JarFile} | sed 's/"//g'`


    echo "\n" >> Dockerfile


    # 注入MY_PROJECT_NAME环境变量

    echo "env MY_PROJECT_NAME \${ProjectName}" >> Dockerfile


    # 注入启动脚本并使用此脚本为容器启动脚本，覆盖Dockerfile中原有的ENTRYPOINT

    echo "ADD axzo_java_app_startup.sh /axzo_java_app_startup.sh" >> Dockerfile

    echo "ADD dependency_tree.txt /dependency_tree.txt" >> Dockerfile

    echo "ENTRYPOINT sh /axzo_java_app_startup.sh \${JarFile}" >> Dockerfile


    cat Dockerfile
  mvDockerBuildDep.py: |-
    #! /usr/bin/env python
    # -*- coding: utf-8 -*-
    import sys
    import subprocess
    import os
    import re
    import json
    import requests
    import hashlib

    def runCommand(commandStr):
        r = subprocess.getstatusoutput(commandStr)
        if r[0] == 0:
            print(r[1])
            return r[1]
        else:
            print(r[1])
            return False

    if not os.path.exists("Dockerfile"):
        print("No Dockerfile found,quit.")
        sys.exit(0)
    if not os.path.exists("dockerBuildOnly"):
        os.mkdir("dockerBuildOnly")

    # java类应用计算包依赖
    axzoDepList = []
    if os.path.exists("/pipeline-stage-share/dependency_tree.txt"):
        for line in open("/pipeline-stage-share/dependency_tree.txt","r"):
            try:
                if re.search(" -> ",line):
                    depLeftGroupId = line.strip().split(" -> ")[0].split("\"")[1].split(":")[0]
                    depLeftArtifactId = line.strip().split(" -> ")[0].split("\"")[1].split(":")[1]

                    depRightGroupId = line.strip().split(" -> ")[1].split("\"")[1].split(":")[0]
                    depRightArtifactId = line.strip().split(" -> ")[1].split("\"")[1].split(":")[1]
                    
                    if depLeftGroupId.startswith("cn.axzo") and depRightGroupId.startswith("cn.axzo"):
                        #print(line.strip())

                        depRight = "{}:{}".format(depRightGroupId,depRightArtifactId)
                        # print(depRight)
                        if depRight not in axzoDepList:
                            axzoDepList.append(depRight)      
            except:
                continue

    # 查询依赖包的版本信息
    with open("/pipeline-stage-share/dependency_tree.txt","w+") as f:
        for axzoDep in axzoDepList:
            if os.getenv("targetEnv") in ["axzo-pro","axzo-live"] or os.getenv("targetEnv").endswith("-prod"):
                repository = "axzo-master"
            else:
                repository = os.getenv("targetEnv")
            url = "https://nexus.axzo.cn/service/rest/v1/search?repository={}&group={}&name={}&sort=version&direction=desc".format(repository,axzoDep.split(":")[0],axzoDep.split(":")[1])
            headers = {
                'content-type': 'application/json',
                'Accept': 'application/json;charset=utf-8'
            }
            try:
                r = requests.get(url=url, headers=headers)
                # print(r.text)
                r_json = json.loads(r.text)
                for i in r_json["items"]:
                    print("{}.{}: {}".format(axzoDep.split(":")[0],axzoDep.split(":")[1],i["version"]))
                    f.write("{}.{}: {}\n".format(axzoDep.split(":")[0],axzoDep.split(":")[1],i["version"]))
                    f.flush()
                    break
            except:
                # traceback.print_exc()
                continue

    # 计算依赖清单md5值
    if os.path.exists("/pipeline-stage-share/dependency_tree.txt"):
        with open("/pipeline-stage-share/dependency_tree.txt", 'rb') as fp:
            data = fp.read()
        file_md5= hashlib.md5(data).hexdigest()

        with open("/pipeline-stage-share/dependency_tree.txt.md5sum","w") as f:
            f.write(file_md5)
            f.flush()
        commandStr = "cat /pipeline-stage-share/dependency_tree.txt > dependency_tree.txt"
        runCommand(commandStr)
        

    depFiles = []
    for line in open("Dockerfile"):
        line = line.strip()
        if line.startswith("COPY") or line.startswith("ADD"):
            lineWords = line.split()
            del lineWords[0]
            del lineWords[-1]
            for depFile in lineWords:
                depFile = depFile.strip("/")
                depFiles.append(depFile)
    depFiles.append("Dockerfile")

    for depFile in depFiles:
        if not os.path.exists(depFile):
            print("Not found: {}".format(depFile))
            sys.exit(1)
        commandStr = "cp --parents -raf {} dockerBuildOnly/".format(depFile)
        print(commandStr)
        r = runCommand(commandStr)
        if r == False:
            sys.exit(1)



    sys.exit(0)
  pomTrack.py: >
    #! /usr/bin/env python

    # -*- coding: utf-8 -*-


    import xml.etree.ElementTree as et

    import sys

    import json

    import os

    import traceback

    import requests


    envName = sys.argv[1]



    def pomTrack(xmlFile,module):
        global deploy_list
        global my_group_id
        deploy_list[module] = {}
        deploy_list[module]["pom"] = xmlFile

        dependency_list_by_pom[xmlFile] = []
        if not os.path.exists(xmlFile):
            print("Not found: ",xmlFile)
            return True
        try:
            tree = et.parse(xmlFile)
            #print(tree)
        except:
            traceback.print_exc()
            return False
        # print(xmlFile)
        root = tree.getroot()
        #print(thisXml.attrib)
        for i in root:
            if i.tag.endswith("name"):
                deploy_list[module]["name"] = i.text
                break
        for i in root:
            if i.tag.endswith("artifactId"):
                deploy_list[module]["artifactId"] = i.text
                break
        for i in root:
            if i.tag.endswith("groupId"):
                my_group_id = i.text
                deploy_list[module]["groupId"] = i.text
                break
        for i in root:
            if i.tag.endswith("packaging"):
                deploy_list[module]["packaging"] = i.text
                break
        for i in root:
            if i.tag.endswith("version"):
                deploy_list[module]["version"] = i.text
                break
        if "groupId" not in deploy_list[module].keys():
            deploy_list[module]["groupId"] = my_group_id
        
        
        for i in root:
            if i.tag.endswith("dependencies"):
                #print("\tdependencies:")
                for j in i:
                    if j.tag.endswith("dependency"):
                        isDepAxzo = False
                        thisMap = {}
                        for k in j:
                            thisMap[k.tag.replace('{http://maven.apache.org/POM/4.0.0}',"")] = k.text
                            if k.tag.replace('{http://maven.apache.org/POM/4.0.0}',"") == "groupId" and k.text.startswith("cn.axzo."):
                                if k.text not in dependency_list.keys():
                                    dependency_list[k.text] = []
                                isDepAxzo = True
                        if isDepAxzo:
                            for k in j:
                                if k.tag.replace('{http://maven.apache.org/POM/4.0.0}',"") == "groupId" and k.text.startswith("cn.axzo."):
                                    dependency_list_by_pom[xmlFile].append(thisMap)
                                    if thisMap["artifactId"] not in dependency_list[k.text]:
                                        dependency_list[k.text].append(thisMap["artifactId"])
                break
        for i in root:
            if i.tag.endswith("modules"):
                for j in i:
                    if j.tag.endswith("module"):
                        xmlFileName = xmlFile.split("/")[-1]
                        moduleXmlFile = "{}/pom.xml".format(xmlFile.replace(xmlFileName,j.text))
                        pomTrack(moduleXmlFile,j.text)

    my_group_id = "None"

    deploy_list = {}

    dependency_list = {}

    dependency_list_by_pom = {}

    pomTrack("./pom.xml","root")       



    # print(json.dumps(deploy_list,sort_keys=True, indent=4,
    ensure_ascii=False))

    # print(json.dumps(dependency_list,sort_keys=True, indent=4,
    ensure_ascii=False))


    print("依赖清单：")

    for k,v in dependency_list.items():
        for x in v:
            if envName in ["axzo-pro","axzo-live"] or envName.endswith("-prod"):
                repository = "axzo-master"
            else:
                repository = envName
            url = "https://nexus.axzo.cn/service/rest/v1/search?repository={}&group={}&name={}&sort=version&direction=desc".format(repository,k,x)
            headers = {
                'content-type': 'application/json',
                'Accept': 'application/json;charset=utf-8'
            }
            try:
                r = requests.get(url=url, headers=headers)
                # print(r.text)
                r_json = json.loads(r.text)
                for i in r_json["items"]:
                    print("{}.{}: {}".format(k,x,i["version"]))
                    break
            except:
                # traceback.print_exc()
                continue
    #print(json.dumps(dependency_list_by_pom,sort_keys=True, indent=4,
    ensure_ascii=False))


    # sys.exit(0)
kind: ConfigMap
metadata:
  name: jenkins-scripts
  namespace: kube-ops
EOF
```

## 创建secrets
```bash
kubectl apply -f - <<EOF
apiVersion: v1
data:
  git-credentials: xxxx
kind: Secret
metadata:
  name: jenkins-secret
  namespace: kube-ops
type: Opaque
EOF
```

## 创建PVC
```bash
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: jenkins-1223
  namespace: kube-ops
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: everest-csi-provisioner
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  storageClassName: sfsturbo-k8s-ops
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: maven
  namespace: kube-ops
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: everest-csi-provisioner
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 550Gi
  storageClassName: sfsturbo-k8s-ops
  volumeMode: Filesystem
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: jnlp-data
  namespace: kube-ops
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: everest-csi-provisioner
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 550Gi
  storageClassName: sfsturbo-k8s-ops
  volumeMode: Filesystem
EOF
```

## 创建deploy service
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: jenkins-new
  name: jenkins-new
  namespace: kube-ops
spec:
  progressDeadlineSeconds: 600
  replicas: 0
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: jenkins-new
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        name: jenkins-new
      name: jenkins-new
    spec:
      automountServiceAccountToken: true
      containers:
        - env:
            - name: JAVA_OPTS
              value: >-
                -Xmx16g -Xms16g -XshowSettings:vm
                -Dhudson.slaves.NodeProvisioner.initialDelay=0
                -Dhudson.slaves.NodeProvisioner.MARGIN=50
                -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85
                -Duser.timezone=Asia/Shanghai
            - name: LIMITS_MEMORY
              valueFrom:
                resourceFieldRef:
                  divisor: '0'
                  resource: limits.memory
          image: 'harbor.axzo.cn/devops/jenkins:2.375.1-lts'
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /login
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 5
            successThreshold: 1
            timeoutSeconds: 2
          name: jenkins-new
          ports:
            - containerPort: 8080
              name: 8080tcp2
              protocol: TCP
            - containerPort: 50000
              name: 50000tcp2
              protocol: TCP
          securityContext:
            privileged: true
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /etc/localtime
              name: tz-config
            - mountPath: /var/jenkins_home
              name: jenkins-1223
      dnsPolicy: ClusterFirst
      hostAliases:
        - hostnames:
            - harbor.axzo.cn
          ip: 172.16.2.25
      imagePullSecrets:
        - name: harbor
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
      serviceAccount: jenkins-blue
      serviceAccountName: jenkins-blue
      terminationGracePeriodSeconds: 10
      volumes:
        - hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai
          name: tz-config
        - name: jenkins-1223
          persistentVolumeClaim:
            claimName: jenkins-1223
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-new
  namespace: kube-ops
spec:
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 8080
    - name: agent
      port: 50000
      protocol: TCP
      targetPort: 50000
  selector:
    name: jenkins-new
  type: NodePort
EOF
```