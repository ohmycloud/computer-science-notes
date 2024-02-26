#show heading: it => {
  set text(red)
  [#it.body]
  v(1em)
}

#show heading.where(level: 1): it => {
  set text(red)
  align(center)[#it.body]
}

#outline(
  title: "目      录",
  target: heading.where(level: 2)
)

= 记一次因为删除 HDFS 数据导致的集群故障修复历程

== 问题描述

NameNode 重启失败, 重要报错日志如下:

```
FATAL org/apache.hdfs.server.namenode.FSEditLog: Error: revoverUnfinalizedSegments failed for required journal
```

== 问题复盘

导致这个问题的原因是因为集群报了磁盘空间不够。删除了一部分 subdir 目录后, 清理出了一部分磁盘空间, 但是 edits 文件有损坏。

== 问题定位

监听 JOURNALNODE 的日志: 

```sh
tail -f /var/log/hadoop-hdfs/hadoop-cmf-hdfs-JOURNALNODE-work001.log.out
tail -f /var/log/hadoop-hdfs/hadoop-cmf-hdfs-JOURNALNODE-work002.log.out
tail -f /var/log/hadoop-hdfs/hadoop-cmf-hdfs-JOURNALNODE-work003.log.out
```

重启 JOURNALNODE, 看到 work001 和 work002 节点的日志如下: 

```
work001: 2023-11-23 11:42:22,809 WARN org.apache.hadoop.hdfs.server.namenode.FSImage: Caught exception after scanning through 0 ops from /mnt/data1/dfs/jn/circue1/current/edits_inprogress_0000000000129404576 while determining its valid length. Position was 176128
work002: 2023-11-23 11:50:07,992 WARN org.apache.hadoop.hdfs.server.namenode.FSImage: Caught exception after scanning through 0 ops from /mnt/data1/dfs/jn/circue1/current/edits_inprogress_0000000000060194739 while determining its valid length. Position was 1044480
```

这说明, 文件 edits_inprogress_0000000000129404576 和文件 edits_inprogress_0000000000060194739 损坏了。

而 work003 的日志正常。

这就导致了集群的 master001 和 master002 节点一直无法重启成功。

== 问题修复

解决方法：把正常节点的 /mnt/data1/dfs/jn/circue1/current 目录下的所有文件复制到不正常节点的对应目录。

```bash
# 备份旧的 JOURNALNODE 数据
tar -zcvf jn_current.tar.gz /mnt/data1/dfs/jn/circue1/current

# 删除旧的 JOURNALNODE 数据
cd /mnt/data1/dfs/jn/circue1/current
rm -rf ./*

# 从其它节点拷贝 JOURNALNODE 数据
scp -r root@work003:/mnt/data1/dfs/jn/circue1/current/* .

# 修正目录权限
chown -R hdfs:hdfs /mnt/data1/dfs/jn/circue1/current
```

然后重启 JOURNALNODE 和 master 角色。
