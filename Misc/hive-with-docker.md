## 本地使用 Docker 安装 hive

# load data into hive

```shell
$ docker-compose exec hive-server bash
  # /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
  > CREATE TABLE pokes (foo INT, bar STRING);
  > LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
```

# 使用 sqoop 列出 mysql 下的所有数据库

```shell
sqoop list-databases --connect jdbc:mysql://localhost:3306 --username root --password xxxxxxxx
```

# 修改 sqoop conf/sqoop-env.sh

设置 HADOOP_COMMON_HOME 和 HADOOP_MAPRED_HOME 变量的值为 docker container 中 Hadoop 的 PATH：

```shell
export HADOOP_COMMON_HOME=/opt/hadoop-2.7.4

#Set path to where hadoop-*-core.jar is available
export HADOOP_MAPRED_HOME=/opt/hadoop-2.7.4
```

# 把 sqoop 复制到容器中的 /opt 目录下

```shell
tar -zcvf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz sqoop-1.4.7.bin__hadoop-2.6.0
docker cp ~/opt/software/sqoop-1.4.7.bin__hadoop-2.6.0.tar.xz 0d263e88dfc5:/opt/

sqoop-1.4.7.bin__hadoop-2.6.0/bin/sqoop import \
    --connect jdbc:mysql://localhost:3306/test \
    --username root \
    --password xxxxxxxx \
    --table mysql_table \
    --hive-import \
    --hive-overwrite --create-hive-table \
    --hive-table default.mysql_table \
    --delete-target-dir
```

把 localhost 换成宿主机的 IP。

```shell
sqoop-1.4.7.bin__hadoop-2.6.0/bin/sqoop import \
    --connect jdbc:mysql://192.168.0.123:3306/test \
    --username root \
    --password xxxxxxxx \
    --table mysql_table \
    --hive-import \
    --hive-overwrite --create-hive-table \
    --hive-table default.mysql_table \
    --delete-target-dir
```

# 进入 hive 容器

```shell
sudo docker images
sudo docker exec -it 0d263e88dfc5 /bin/bash
sudo docker exec -it 41fb4e7c044c /bin/bash
```

# 连接 hive

```shell
sudo docker-compose exec hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

退出：`!exit`。

## 修改 Docker 的配置

把 docker container 中的 hive-site.xml 和 hive-default.xml 文件复制到宿主机的 /tmp 目录中:

```bash
docker cp 0d263e88dfc5:/opt/hive/conf/hive-site.xml /tmp/
docker cp 0d263e88dfc5:/opt/hive/conf/hive-default.xml.template /tmp/
```

重启 docker hive 容器：

```shell
sudo docker-compose down
sudo docker-compose up -d
```
 
重启后容器名变了, 环境也重新创建了, 修改后的配置也没有了。

# 参考连接

- https://blog.csdn.net/l1028386804/article/details/80216911
- https://dzone.com/articles/sqoop-import-data-from-mysql-to-hive
- https://github.com/JuntaoLiu01/Hadoop-Hive
- https://blog.csdn.net/l1028386804/article/details/80216911
- https://juejin.im/post/6844903907546628104
- https://github.com/big-data-europe/docker-hive
