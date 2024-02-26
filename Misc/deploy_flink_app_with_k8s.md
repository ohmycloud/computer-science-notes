# 在 k8s 上部署 Apache Flink 应用程序

## 创建一个带有 Flink job 的 Docker 镜像

创建一个名为 Dockerfile 的文件:

```bash
ssh dev-host3
cd /opt/scripts/Flink
touch Dockerfile
```

Dockerfile 文件的内容如下:

```yaml
FROM flink:1.17.0
RUN mkdir -p $FLINK_HOME/usrlib
COPY charge-energy-app-1.0.jar $FLINK_HOME/usrlib/charge-energy-app-1.0.jar
```

使用上面的 Dockerfile 构建一个用户镜像, 并把它推送到你的远程镜像仓库:

```bash
docker build -t charge_energy_app -f Dockerfile .
docker push charge_energy_app 10.0.0.109:5000/charge-energy-app:latest
```

创建完镜像后, 使用 docker images 查看:

```
[root@host3 Flink]# docker build -t charge_energy_app -f Dockerfile .
Sending build context to Docker daemon  172.8MB
Step 1/3 : FROM flink:1.17.0
 ---> af1541b7ee9b
Step 2/3 : RUN mkdir -p $FLINK_HOME/usrlib
 ---> Using cache
 ---> 96d7a07c09fd
Step 3/3 : COPY charge-energy-app-1.0.jar $FLINK_HOME/usrlib/charge-energy-app-1.0.jar
 ---> 1530fd51257a
Successfully built 1530fd51257a
Successfully tagged charge_energy_app:latest
```

看到已经成功创建镜像:

```
[root@host3 Flink]# docker images
REPOSITORY                                                        TAG             IMAGE ID       CREATED              SIZE
charge_energy_app                                                 latest          1530fd51257a   About a minute ago   954MB
flink                                                             1.17.0          af1541b7ee9b   3 weeks ago          781MB
```

打上 tag, 然后上传到 Docker 私有仓库:

```bash
docker tag charge_energy_app:latest 10.0.0.109:5000/charge-energy-app:latest
docker push 10.0.0.109:5000/charge-energy-app
```

打开 http://10.0.0.109:5000/v2/_catalog, 看到仓库中已经出现了:

```json
{"repositories":["charge-energy-app","hello-world"]}
```

## 启动一个 Flink Application Cluster

```bash
$ ./bin/flink run-application \
    --detached \
    --parallelism 4 \
    --target kubernetes-application \
    -Dkubernetes.cluster-id=k8s-ha-app-1 \
    -Dkubernetes.container.image=charge-energy-app \
    -Dkubernetes.jobmanager.cpu=0.5 \
    -Dkubernetes.taskmanager.cpu=0.5 \
    -Dtaskmanager.numberOfTaskSlots=4 \
    -Dkubernetes.rest-service.exposed.type=NodePort \
    -Dhigh-availability=org.apache.flink.kubernetes.highavailability.KubernetesHaServicesFactory \
    -Dhigh-availability.storageDir=hdfs://flink-bucket/flink-ha \
    -Drestart-strategy=fixed-delay \
    -Drestart-strategy.fixed-delay.attempts=10 \
    -Dcontainerized.master.env.ENABLE_BUILT_IN_PLUGINS=flink-s3-fs-hadoop-1.12.1.jar \
    -Dcontainerized.taskmanager.env.ENABLE_BUILT_IN_PLUGINS=flink-s3-fs-hadoop-1.12.1.jar \
    local:///opt/flink/usrlib/my-flink-job.jar
```

## 参考连接

- https://flink.apache.org/2021/02/10/how-to-natively-deploy-flink-on-kubernetes-with-high-availability-ha/

