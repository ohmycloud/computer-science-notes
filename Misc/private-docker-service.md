# 私有 Docker 镜像仓库搭建

## 安装 registry

```bash
ssh dev-host4

docker pull registry
```

默认拉取最新版:

```
[root@host4 ~]# docker pull registry
Using default tag: latest
latest: Pulling from library/registry
79e9f2f55bf5: Pull complete
0d96da54f60b: Pull complete
5b27040df4a2: Pull complete
e2ead8259a04: Pull complete
3790aef225b9: Pull complete
Digest: sha256:169211e20e2f2d5d115674681eb79d21a217b296b43374b8e39f97fcf866b375
Status: Downloaded newer image for registry:latest
docker.io/library/registry:latest
```

## 配置私有仓库地址

```bash
vi /etc/docker/daemon.json
```

添加 "insecure-registries" 键, 值为本机的 IP 地址+端口:

```json
{
  "insecure-registries": ["127.0.0.1:5000"],
  "registry-mirrors": ["https://82m9ar63.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
```

重启 docker:

```bash
systemctl restart docker
```

创建容器:

```bash
docker run -d -p 5000:5000 --name registry docker.io/registry
```

部分参数说明:

- -d: 让容器在后台运行
- -p: 指定容器内部使用的网络端口映射到我们使用的主机上
- --name: 指定容器创建的名称

重新加载配置:

```bash
sudo systemctl daemon-reload
```

然后浏览器访问: http://127.0.0.1:5000/v2/_catalog

验证上传镜像到私有仓库

拉取一个 hello-world 镜像到本地:

```bash
docker pull hello-world
```

查看镜像:

```
[root@host4 ~]# docker images
REPOSITORY                                           TAG       IMAGE ID       CREATED         SIZE
registry.cn-qingdao.aliyuncs.com/dataease/dataease   v1.15.3   dadcc994c341   6 months ago    847MB
registry.cn-qingdao.aliyuncs.com/dataease/mysql      5.7.39    eb175b0743cc   6 months ago    433MB
registry                                             latest    b8604a3fe854   17 months ago   26.2MB
hello-world
```

使用 push 把 hello-world 镜像推送到刚搭建好的私有仓库中:

```bash
# 标记 hello-world 镜像
docker tag hello-world:latest 127.0.0.1:5000/hello-world:latest

# 通过 push 指令推送到私有仓库
docker push 127.0.0.1:5000/hello-world:latest
```

```
[root@host4 ~]# docker tag hello-world:latest 127.0.0.1:5000/hello-world:latest
[root@host4 ~]# docker images
REPOSITORY                                           TAG       IMAGE ID       CREATED         SIZE
registry.cn-qingdao.aliyuncs.com/dataease/dataease   v1.15.3   dadcc994c341   6 months ago    847MB
registry.cn-qingdao.aliyuncs.com/dataease/mysql      5.7.39    eb175b0743cc   6 months ago    433MB
registry                                             latest    b8604a3fe854   17 months ago   26.2MB
127.0.0.1:5000/hello-world                           latest    feb5d9fea6a5   19 months ago   13.3kB
hello-world                                          latest    feb5d9fea6a5   19 months ago   13.3kB
[root@host4 ~]#
[root@host4 ~]# docker push 127.0.0.1:5000/hello-world:latest
The push refers to repository [127.0.0.1:5000/hello-world]
e07ee1baac5f: Pushed
latest: digest: sha256:f54a58bc1aac5ea1a25d796ae155dc228b3f0e11d046ae276b39c4bf2f13d8c4 size: 525
```

再次用浏览器访问 http://127.0.0.1:5000/v2/_catalog, 返回一个 JSON:

```json
{"repositories":["hello-world"]}
```

## 参考文章

- https://cloud.tencent.com/developer/article/1639614
