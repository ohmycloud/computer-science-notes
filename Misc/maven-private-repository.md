# maven私有仓库搭建

下载 nexus 压缩包, 解压 到 /usr/local 目录:

```bash
tar -xvf nexus-3.53.0-01-unix.tar.gz -C /usr/local/
```

创建软链接:

```bash
ln -s /usr/local/nexus-3.53.0-01/ /usr/local/nexus
ln -s /usr/local/nexus/bin/nexus /usr/bin/
```

修改配置:

```bash
cd /usr/local/nexus
vi bin/nexus.rc
vi etc/nexus-default.properties
vi bin/nexus.vmoptions
```

创建服务:

```bash
vi /lib/systemd/system/nexus.service

systemctl daemon-reload
systemctl enable --now nexus.service
ss -ntlp | grep 3333
```

# 查看密码

```bash
cat /usr/local/sonatype-work/nexus3/admin.password
```

浏览器打开: http://host-ip:3333/

输入 admin 的密码, 修改新的密码。

再创建新的仓库。

# 本地 maven 配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- for full reference, see also http://maven.apache.org/ref/3.2.3/maven-settings/settings.html -->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>/home/user/.m2/repository</localRepository>
  <mirrors>
    <mirror>
      <id>example</id>
      <mirrorOf>*</mirrorOf>
      <url>http://127.0.0.1:8081/repository/maven-public/</url>
    </mirror>
  </mirrors>

  <servers>
    <server>
        <id>releases</id>
        <username>username</username>
        <password>password</password>
    </server>
    <server>
        <id>snapshots</id>
        <username>username</username>
        <password>password</password>
    </server>
  </servers>

 <!-- 这个默认配置决定了我们的Maven服务器开启snapshot配置，否则不能下载SNAPSHOTS的相关资源 --> 
 <profiles>
    <profile>
      <id>example</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <properties>
        <altReleaseDeploymentRepository>
          example-releases::default::http://127.0.0.1:8081/repository/maven-releases/
        </altReleaseDeploymentRepository>
        <altSnapshotDeploymentRepository>
          example-snapshots::default::http://127.0.0.1:8081/repository/maven-snapshots/
        </altSnapshotDeploymentRepository>
      </properties>
      <repositories>
        <repository>
          <id>example-releases</id>
          <url>http://127.0.0.1:8081/repository/maven-releases/</url>
          <releases>
            <enabled>true</enabled>
          </releases>
          <snapshots>
            <enabled>false</enabled>
          </snapshots>
        </repository>
        <repository>
          <id>example-snapshots</id>
          <url>http://127.0.0.1:8081/repository/maven-snapshots/</url>
          <releases>
            <enabled>false</enabled>
            </releases>
          <snapshots>
            <enabled>true</enabled>
            <updatePolicy>always</updatePolicy>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
</settings>
```
